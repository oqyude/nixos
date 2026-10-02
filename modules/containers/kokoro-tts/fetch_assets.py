"""Bake every kokoro-ru asset the server needs into the image.

Two things make a plain `FROM python` image useless for this model at runtime,
and both are fixed here at build time:

  * kokoro-ru's checkpoints and its recompiled espeak-ng data live in the HF
    cache by default, and the HF cache is part of the disposable container
    layer, so every `podman run` would re-download ~700 MB.
  * ruaccent writes its ONNX models, dictionaries and Koziev data into its own
    `site-packages/ruaccent` directory. It only downloads when those files are
    missing, so a single `load()` here means the runtime never touches the
    network.

RuG2P resolves espeak-data/ and kokoro-config.json relative to ru_g2p.py, so
the snapshot layout has to stay flat inside KOKORO_MODEL_DIR.
"""

from __future__ import annotations

import logging
import os
from pathlib import Path

from huggingface_hub import snapshot_download

REPO = os.environ.get("KOKORO_RU_REPO", "zaakirio/kokoro-ru")
# A commit, not a branch: "main" would silently change the weights under a
# rebuild that only touched an unrelated line of the Nix module.
REVISION = os.environ.get("KOKORO_RU_REVISION", "main")
DEST = Path(os.environ.get("KOKORO_MODEL_DIR", "/app/kokoro-ru"))

VOICES = [v.strip() for v in os.environ.get("KOKORO_RU_VOICES", "sveta,masha,dima").split(",") if v.strip()]

# sveta and masha share one checkpoint and differ only by voicepack, so the two
# female voices cost one 327 MB download, not two.
CHECKPOINTS = {
    "sveta": "kokoro-ru-v2-base.pth",
    "masha": "kokoro-ru-v2-base.pth",
    "dima": "kokoro-ru-v2-dima.pth",
}

PATTERNS = [
    # KModel reads config.json; RuG2P reads kokoro-config.json for the phoneme
    # vocab. They are not the same file and both are required.
    "config.json",
    "kokoro-config.json",
    "ru_g2p.py",
    # Stock espeak-ng ru_dict ignores combining-acute stress marks, which is the
    # one thing this whole front-end exists to fix. The model repo ships a
    # recompiled dictsource; there is no substitute to fall back to.
    "espeak-data/**",
    *(CHECKPOINTS[v] for v in VOICES if v in CHECKPOINTS),
    *(f"voices/{v}.pt" for v in VOICES),
]


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

    DEST.mkdir(parents=True, exist_ok=True)
    snapshot_download(
        repo_id=REPO,
        revision=REVISION,
        allow_patterns=PATTERNS,
        local_dir=str(DEST),
    )
    logging.info("kokoro-ru assets in %s at %s", DEST, REVISION)

    missing = [name for name in VOICES if not (DEST / "voices" / f"{name}.pt").exists()]
    if missing:
        raise SystemExit(f"voice packs missing after download: {missing}")

    # Warm ruaccent into site-packages so `load()` short-circuits at runtime.
    from ruaccent import RUAccent

    accent = RUAccent()
    accent.load(omograph_model_size="turbo3.1", use_dictionary=True, tiny_mode=False)
    logging.info("ruaccent warm: %s", accent.process_all("Здравствуйте, как ваши дела?"))


if __name__ == "__main__":
    main()