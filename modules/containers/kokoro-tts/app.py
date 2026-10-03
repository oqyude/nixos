"""OpenAI-compatible TTS API backed by zaakirio/kokoro-ru.

The model itself is language-blind: phoneme ids in, 24 kHz audio out. All the
Russian lives in the G2P front-end, and the one that matters is kokoro-ru's own
`ru_g2p.py` — RUAccent resolves lexical stress, ё and homographs, then an
acute-aware espeak-ng phonemizer turns that into IPA. Stock misaki Russian is
espeak-only and gets stress wrong often enough that the model reads as
non-native (measured 27% vs 22% round-trip WER, per the model card).

So: text -> RuG2P.phonemize -> KModel(ipa, voicepack[len(ipa) - 1]) -> waveform.

Endpoints
    POST /v1/audio/speech          OpenAI text-to-speech
    POST /v1/audio/speech/stream   same, but mp3/opus emitted while synthesising
    GET  /v1/models                OpenAI model list
    GET  /v1/voices                voice inventory (extension, not part of OpenAI)
    GET  /healthz                  readiness, 503 until the model is loaded
"""

from __future__ import annotations

import io
import logging
import os
import queue
import re
import subprocess
import sys
import threading
import wave
from contextlib import asynccontextmanager
from pathlib import Path
from typing import TYPE_CHECKING, Iterator, Literal

import numpy as np
from fastapi import FastAPI
from fastapi.responses import JSONResponse, Response, StreamingResponse
from pydantic import BaseModel, ConfigDict, Field

if TYPE_CHECKING:  # torch is imported lazily so /healthz answers during boot
    import torch

MODEL_ID = "kokoro-ru"
SAMPLE_RATE = 24000
MODEL_DIR = Path(os.environ.get("KOKORO_MODEL_DIR", "/app/kokoro-ru"))
DEFAULT_VOICE = os.environ.get("KOKORO_DEFAULT_VOICE", "sveta")
# Measured on the host this was tuned for (Ryzen AI 9 HX 370, 24 logical cores):
# median end-to-end latency for a 5.6 s utterance was 1.203 s @ 4 threads,
# 1.066 s @ 8, 0.979 s @ 12, 0.980 s @ 16, then 1.87 s @ 24. The gain stops at
# the physical core count and SMT oversubscription costs ~2x, so cap instead of
# trusting os.cpu_count(), which reports logical CPUs. Override on other hosts.
THREADS = int(os.environ.get("KOKORO_THREADS", min(12, os.cpu_count() or 4)))
# 2026-07-29, when the kokoro-ru revision we pin was published. Clients that
# cache on this treat any change as a new model, so it must stay stable.
MODEL_CREATED = 1785353253

# voice -> (checkpoint stem, gender). The checkpoint carries the timbre and the
# voicepack the identity, which is why sveta and masha share one file.
VOICE_SPECS: dict[str, tuple[str, str]] = {
    "sveta": ("kokoro-ru-v2-base", "female"),
    "masha": ("kokoro-ru-v2-base", "female"),
    "dima": ("kokoro-ru-v2-dima", "male"),
}

# Clients that ship the OpenAI voice list (alloy, nova, echo, ...) send those
# names unless the user overrides them, so map them onto the three we have.
VOICE_ALIASES: dict[str, str] = {
    "alloy": "sveta",
    "ash": "sveta",
    "ballad": "sveta",
    "verse": "sveta",
    "marin": "sveta",
    "coral": "masha",
    "sage": "masha",
    "shimmer": "masha",
    "cedar": "masha",
    "echo": "dima",
    "fable": "dima",
    "onyx": "dima",
}

CONTENT_TYPES = {
    "wav": "audio/wav",
    "mp3": "audio/mpeg",
    "opus": "audio/ogg",
    "aac": "audio/aac",
    "flac": "audio/flac",
    "pcm": "audio/pcm",
}

# Everything except wav and pcm goes through ffmpeg; those two are byte-exact
# from the stdlib and need no encoder at all.
FFMPEG_ARGS = {
    "mp3": ["-c:a", "libmp3lame", "-q:a", "2"],
    "opus": ["-c:a", "libopus", "-b:a", "64k"],
    "aac": ["-c:a", "aac", "-b:a", "128k"],
    "flac": ["-c:a", "flac"],
}
FFMPEG_CONTAINERS = {"mp3": "mp3", "opus": "ogg", "aac": "adts", "flac": "flac"}

# Kokoro's Albert context is 510 tokens and KModel.forward asserts
# len(ids) + 2 <= 510, so 508 phonemes is the hard ceiling per forward pass.
MAX_PHONEMES = 508
# Roughly 300 characters of Russian lands near 400 phonemes, comfortably under
# the ceiling, and keeps a chunk short enough that a bad sentence is a short
# chunk.
CHUNK_CHARS = 300
# Silence inserted between chunks. Without it the concatenation clicks at every
# boundary because each forward pass starts and ends on a zero crossing.
CHUNK_GAP_S = 0.08

_SENTENCE_SPLIT = re.compile(r"(?<=[.!?…])\s+")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("kokoro-ru")


def split_text(text: str, budget: int = CHUNK_CHARS) -> list[str]:
    """Split into sentence-bounded chunks, hard-cutting only as a last resort.

    Phonemizing per sentence rather than per paragraph keeps RUAccent's stress
    decisions local and gives the model a reset point at every full stop.
    """
    chunks: list[str] = []
    current = ""
    for sentence in _SENTENCE_SPLIT.split(text.strip()):
        sentence = sentence.strip()
        while len(sentence) > budget:
            if current:
                chunks.append(current)
                current = ""
            chunks.append(sentence[:budget])
            sentence = sentence[budget:].strip()
        if not sentence:
            continue
        if len(current) + len(sentence) + 1 > budget:
            # Guarded: when the first sentence fills the budget exactly, or the
            # previous one was hard-cut down to nothing, `current` is empty and
            # a bare append would queue a zero-length chunk.
            if current:
                chunks.append(current)
            current = sentence
        else:
            current = f"{current} {sentence}".strip()
    if current:
        chunks.append(current)
    return chunks


def split_phonemes(ps: str, limit: int = MAX_PHONEMES) -> list[str]:
    """Cut an over-long phoneme string on word boundaries."""
    if len(ps) <= limit:
        return [ps]
    parts: list[str] = []
    rest = ps
    while len(rest) > limit:
        cut = rest.rfind(" ", 0, limit)
        if cut <= 0:
            cut = limit
        parts.append(rest[:cut].strip())
        rest = rest[cut:].strip()
    if rest:
        parts.append(rest)
    return [part for part in parts if part]


class KokoroRu:
    """Loaded model plus the G2P front-end, behind a single inference lock."""

    def __init__(self) -> None:
        self._torch: torch | None = None
        self._g2p = None
        self._models: dict[str, torch.nn.Module] = {}
        self._packs: dict[str, torch.Tensor] = {}
        # The Albert encoder and the iSTFTNet decoder keep per-call scratch
        # buffers; concurrent forwards on one model interleave into them. The
        # model is fast enough on CPU that serialising is not the bottleneck.
        self._lock = threading.Lock()

    def load(self) -> None:
        import torch
        from kokoro import KModel

        torch.set_num_threads(THREADS)
        self._torch = torch

        # RuG2P is imported from the baked snapshot, not installed, and it
        # resolves espeak-data/ plus kokoro-config.json next to itself.
        sys.path.insert(0, str(MODEL_DIR))
        from ru_g2p import RuG2P

        self._g2p = RuG2P(
            espeak_data=MODEL_DIR / "espeak-data",
            vocab_path=MODEL_DIR / "kokoro-config.json",
        )

        for stem in sorted({stem for stem, _ in VOICE_SPECS.values()}):
            checkpoint = MODEL_DIR / f"{stem}.pth"
            if not checkpoint.exists():
                log.warning("checkpoint %s missing, voices using it stay unavailable", checkpoint)
                continue
            # repo_id is only used to build the default model filename; passing
            # both config and model keeps it from touching the HF cache at all.
            self._models[stem] = KModel(
                repo_id=str(MODEL_DIR),
                config=str(MODEL_DIR / "config.json"),
                model=str(checkpoint),
            ).eval()
            log.info("loaded checkpoint %s", checkpoint.name)

        for name in VOICE_SPECS:
            pack = MODEL_DIR / "voices" / f"{name}.pt"
            if pack.exists():
                self._packs[name] = torch.load(str(pack), map_location="cpu", weights_only=True)

        if not self.available_voices():
            raise RuntimeError(f"no usable voices under {MODEL_DIR}")

    def available_voices(self) -> list[str]:
        return [
            name
            for name in VOICE_SPECS
            if name in self._packs and VOICE_SPECS[name][0] in self._models
        ]

    def phonemes(self, text: str):
        for chunk in split_text(text):
            ps, _oov = self._g2p.phonemize(chunk)
            ps = ps.strip()
            if ps:
                yield from split_phonemes(ps)

    def iter_audio_chunks(self, text: str, voice: str, speed: float):
        """Yields float32 audio per phoneme chunk, silence gaps interleaved.

        The engine lock is held for the whole iteration, so a caller that stops
        consuming early releases synthesis for everyone else.
        """
        torch = self._torch
        assert torch is not None, "synthesize() before load()"
        stem, _gender = VOICE_SPECS[voice]
        model = self._models[stem]
        pack = self._packs[voice]

        gap = np.zeros(int(CHUNK_GAP_S * SAMPLE_RATE), dtype=np.float32)
        with self._lock:
            for index, ps in enumerate(self.phonemes(text)):
                # The style vector is picked by phoneme-string length, which is
                # why the model sounds deterministic for identical text.
                style = pack[len(ps) - 1]
                # The packs ship as [510, 256]; KModel wants a batch of one.
                if style.dim() == 1:
                    style = style.unsqueeze(0)
                if index:
                    yield gap
                yield np.asarray(
                    model(ps, style, speed, return_output=True).audio,
                    dtype=np.float32,
                ).reshape(-1)

    def synthesize(self, text: str, voice: str, speed: float) -> np.ndarray:
        chunks = list(self.iter_audio_chunks(text, voice, speed))
        if not chunks:
            return np.zeros(0, dtype=np.float32)
        return np.concatenate(chunks)


def encode(audio: np.ndarray, fmt: str) -> bytes:
    clipped = np.clip(audio, -1.0, 1.0)
    if fmt == "pcm":
        # OpenAI's pcm is raw signed 16-bit little-endian mono at 24 kHz.
        return (clipped * 32767.0).astype("<i2").tobytes()

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes((clipped * 32767.0).astype("<i2").tobytes())
    wav = buffer.getvalue()

    if fmt == "wav":
        return wav

    import imageio_ffmpeg

    command = [
        imageio_ffmpeg.get_ffmpeg_exe(),
        "-hide_banner",
        "-loglevel",
        "error",
        "-i",
        "pipe:0",
        "-ar",
        str(SAMPLE_RATE),
        "-ac",
        "1",
        *FFMPEG_ARGS[fmt],
        "-f",
        FFMPEG_CONTAINERS[fmt],
        "pipe:1",
    ]
    done = subprocess.run(command, input=wav, capture_output=True, check=False)
    if done.returncode != 0:
        raise RuntimeError(done.stderr.decode("utf-8", "replace").strip()[-400:])
    return done.stdout


class StreamEncoder:
    """One long-lived ffmpeg per request: raw PCM in, encoded bytes out.

    A single process is what keeps the container valid. Handing it the audio in
    pieces as they are synthesised avoids any byte-level concatenation, whereas
    encoding the pieces separately and joining the results would emit chained
    Ogg for opus, which plenty of players reject.
    """

    def __init__(self, fmt: str) -> None:
        import imageio_ffmpeg

        self._proc = subprocess.Popen(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-hide_banner",
                "-loglevel",
                "error",
                "-f",
                "s16le",
                "-ar",
                str(SAMPLE_RATE),
                "-ac",
                "1",
                "-i",
                "pipe:0",
                *FFMPEG_ARGS[fmt],
                "-f",
                FFMPEG_CONTAINERS[fmt],
                "pipe:1",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self._blocks: queue.Queue[bytes | None] = queue.Queue()
        self._reader = threading.Thread(target=self._pump, daemon=True)
        self._reader.start()

    def _pump(self) -> None:
        assert self._proc.stdout is not None
        while True:
            block = self._proc.stdout.read(8192)
            if not block:
                break
            self._blocks.put(block)
        self._blocks.put(None)

    def push(self, audio: np.ndarray) -> None:
        assert self._proc.stdin is not None
        clipped = np.clip(audio, -1.0, 1.0)
        self._proc.stdin.write((clipped * 32767.0).astype("<i2").tobytes())
        self._proc.stdin.flush()

    def drain(self) -> Iterator[bytes]:
        """Yields whatever ffmpeg has already emitted, without waiting for more."""
        while True:
            try:
                block = self._blocks.get_nowait()
            except queue.Empty:
                return
            if block is None:
                return
            yield block

    def finish(self) -> Iterator[bytes]:
        assert self._proc.stdin is not None
        self._proc.stdin.close()
        self._reader.join(timeout=120)
        code = self._proc.wait(timeout=30)
        error = self._proc.stderr.read().decode("utf-8", "replace").strip()[-400:]
        if code != 0:
            raise RuntimeError(error or f"ffmpeg exited with {code}")
        yield from self.drain()

    def abort(self) -> None:
        if self._proc.poll() is None:
            self._proc.kill()


engine = KokoroRu()
state: dict[str, str | None] = {"status": "loading", "error": None}


def boot() -> None:
    try:
        engine.load()
        state["status"] = "ready"
        log.info("ready: voices=%s", ", ".join(engine.available_voices()))
    except Exception as exc:
        state["status"] = "error"
        state["error"] = f"{type(exc).__name__}: {exc}"
        log.exception("model failed to load")


@asynccontextmanager
async def lifespan(_app: FastAPI):
    # Off the event loop: loading pulls ~700 MB of weights and runs three ONNX
    # sessions, and /healthz has to stay answerable while it happens.
    threading.Thread(target=boot, name="kokoro-load", daemon=True).start()
    yield


app = FastAPI(title="kokoro-ru OpenAI TTS", version="1.0.0", lifespan=lifespan)

Format = Literal["mp3", "opus", "aac", "flac", "wav", "pcm"]


class SpeechRequest(BaseModel):
    # `protected_namespaces` silences pydantic's warning about the `model_`
    # prefix; `extra="ignore"` absorbs the fields newer OpenAI clients add
    # (instructions, the legacy `format` alias) without failing the request.
    model_config = ConfigDict(extra="ignore", protected_namespaces=())

    input: str = Field(min_length=1)
    model: str = MODEL_ID
    voice: str | None = None
    response_format: Format = "wav"
    speed: float | None = Field(default=None, ge=0.25, le=4.0)


class StreamSpeechRequest(SpeechRequest):
    # Streaming needs a container that tolerates unknown length up front, so wav
    # (whose header declares the final sizes) and the raw formats are out. mp3
    # and opus emit bytes as they go, which is the whole point of the endpoint.
    response_format: Literal["mp3", "opus"] = "mp3"


def fail(status: int, message: str, param: str | None = None, code: str | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        content={
            "error": {
                "message": message,
                "type": "invalid_request_error" if status < 500 else "server_error",
                "param": param,
                "code": code,
            }
        },
    )


def resolve_voice(requested: str | None) -> str | None:
    name = (requested or DEFAULT_VOICE).strip().lower()
    name = VOICE_ALIASES.get(name, name)
    return name if name in engine.available_voices() else None


# response_model=None: the handler returns a Response subclass directly, and
# FastAPI would otherwise try to build a Pydantic model out of the union.
@app.post("/v1/audio/speech", response_model=None)
def create_speech(request: SpeechRequest) -> Response | JSONResponse:
    if state["status"] != "ready":
        return fail(503, f"model is not ready: {state['status']}", code="model_not_ready")

    voice = resolve_voice(request.voice)
    if voice is None:
        available = ", ".join(engine.available_voices())
        return fail(
            400,
            f"unknown voice {request.voice!r}; available: {available}",
            param="voice",
            code="unknown_voice",
        )

    try:
        audio = engine.synthesize(request.input, voice, request.speed or 1.0)
    except Exception as exc:
        log.exception("synthesis failed")
        return fail(500, f"synthesis failed: {exc}", code="synthesis_failed")

    if audio.size == 0:
        return fail(
            400,
            "input contains no speakable text for the Russian G2P",
            param="input",
            code="no_phonemes",
        )

    try:
        payload = encode(audio, request.response_format)
    except Exception as exc:
        log.exception("encoding to %s failed", request.response_format)
        return fail(500, f"encoding to {request.response_format} failed: {exc}", code="encoding_failed")

    return Response(
        content=payload,
        media_type=CONTENT_TYPES[request.response_format],
        headers={"model-id": MODEL_ID, "voice-id": voice},
    )


# response_model=None for the same reason as create_speech above.
@app.post("/v1/audio/speech/stream", response_model=None)
def stream_speech(request: StreamSpeechRequest) -> Response | JSONResponse:
    if state["status"] != "ready":
        return fail(503, f"model is not ready: {state['status']}", code="model_not_ready")

    voice = resolve_voice(request.voice)
    if voice is None:
        available = ", ".join(engine.available_voices())
        return fail(
            400,
            f"unknown voice {request.voice!r}; available: {available}",
            param="voice",
            code="unknown_voice",
        )

    chunks = engine.iter_audio_chunks(request.input, voice, request.speed or 1.0)
    try:
        # Pulled before responding: once the status line is sent it cannot become
        # a 400, and input with no speakable text has to keep failing that way.
        first = next(chunks)
    except StopIteration:
        return fail(
            400,
            "input contains no speakable text for the Russian G2P",
            param="input",
            code="no_phonemes",
        )

    def body() -> Iterator[bytes]:
        encoder = StreamEncoder(request.response_format)
        try:
            encoder.push(first)
            yield from encoder.drain()
            for chunk in chunks:
                encoder.push(chunk)
                yield from encoder.drain()
            yield from encoder.finish()
        except Exception:
            log.exception("streaming synthesis failed")
            raise
        finally:
            chunks.close()
            encoder.abort()

    return StreamingResponse(
        body(),
        media_type=CONTENT_TYPES[request.response_format],
        headers={"model-id": MODEL_ID, "voice-id": voice},
    )


@app.get("/v1/models")
def list_models() -> dict:
    return {
        "object": "list",
        "data": [{"id": MODEL_ID, "object": "model", "created": MODEL_CREATED, "owned_by": "zaakirio"}],
    }


@app.get("/v1/voices")
def list_voices() -> dict:
    return {
        "object": "list",
        "ready": state["status"] == "ready",
        "data": [
            {"id": name, "object": "voice", "checkpoint": VOICE_SPECS[name][0], "gender": VOICE_SPECS[name][1]}
            for name in engine.available_voices()
        ],
    }


@app.get("/healthz")
def healthz() -> JSONResponse:
    ready = state["status"] == "ready"
    return JSONResponse(
        status_code=200 if ready else 503,
        content={
            "status": state["status"],
            "model": MODEL_ID,
            "voices": engine.available_voices(),
            "sample_rate": SAMPLE_RATE,
            "error": state["error"],
        },
    )