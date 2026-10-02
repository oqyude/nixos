FROM python:3.12-slim-bookworm

# Pinned, not "main": a rebuild that only touched the Nix module must not
# silently pick up different weights. Bump these deliberately.
ARG KOKORO_RU_REPO=zaakirio/kokoro-ru
ARG KOKORO_RU_REVISION=d649c57b239b18c4c384378127cbf01dba039bc1
# Trim to "sveta" to halve the image: masha shares her checkpoint and dima is
# a second 327 MB one.
ARG KOKORO_RU_VOICES=sveta,masha,dima

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HF_HUB_DISABLE_TELEMETRY=1 \
    HF_HUB_DISABLE_SYMLINKS_WARNING=1 \
    KOKORO_RU_REPO=${KOKORO_RU_REPO} \
    KOKORO_RU_REVISION=${KOKORO_RU_REVISION} \
    KOKORO_RU_VOICES=${KOKORO_RU_VOICES} \
    KOKORO_MODEL_DIR=/app/kokoro-ru \
    KOKORO_THREADS=4 \
    OMP_NUM_THREADS=4 \
    MKL_NUM_THREADS=4 \
    TZ=Europe/Moscow

WORKDIR /app

# libgomp1 is torch's OpenMP runtime. espeak-ng comes from the espeakng-loader
# wheel rather than the distro package because the model needs its own
# recompiled ru_dict, and libsndfile is absent because WAV/PCM are written with
# stdlib `wave` while every other format goes through imageio-ffmpeg.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# CPU-only torch from its own index: the default PyPI wheel drags in ~2.5 GB of
# CUDA libraries for a machine that has no GPU.
RUN pip install --index-url https://download.pytorch.org/whl/cpu torch

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY app.py fetch_assets.py ./

# Bakes the checkpoints, the acute-aware espeak data and ruaccent's ONNX models
# into the layer, which is what lets the container start with no network and no
# writable volume.
RUN python fetch_assets.py

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=180s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=4)"]

# No workers: the model is a shared in-process singleton, so a second worker
# would only mean a second copy of ~2 GB of weights.
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]