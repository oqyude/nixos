# Auto-generated: engipy backend wheels (PyPI + pytorch.org for CPU-only torch).
#
# Сгенерировано в WSL nixos (linux x86_64) через pip download + nix hash path.
# Не редактировать вручную — регенерировать через /tmp/work/engipy-build.
{ pkgs }:
{
  fastapi = pkgs.fetchPip {
    pname = "fastapi";
    version = "0.115.6";
    hash = "sha256-0KdOeAMtZe31zOSHi5ypzc0KZPvMfbkOIHU8CFuHm8Q=";
  };
  uvicorn = pkgs.fetchPip {
    pname = "uvicorn";
    version = "0.32.0";
    hash = "sha256-+H/qqUuoJuLwrCpEA8ZRk3Vizk8EEcz+vCsDjsZaD50=";
  };
  pydantic = pkgs.fetchPip {
    pname = "pydantic";
    version = "2.10.3";
    hash = "sha256-XFQeA1Hpht7wWlFiWstpM6e3tiqfl0sr6+XWp50UfBg=";
  };
  pydantic-settings = pkgs.fetchPip {
    pname = "pydantic-settings";
    version = "2.7.0";
    hash = "sha256-fCtjrxKweqJrKTGT8V9DQqb9rtfdBNrBQ+1klLSJQV4=";
  };
  sqlalchemy = pkgs.fetchPip {
    pname = "sqlalchemy";
    version = "2.0.36";
    hash = "sha256-bcOPiAJYOVa48iaQiPZ5MwZjUWMowuXtngq87r6e6j4=";
  };
  numpy = pkgs.fetchPip {
    pname = "numpy";
    version = "2.2.1";
    hash = "sha256-nCwAsoNzwn/bCNC0zrwZLipQqk8QP7tVkIIBMLSx2BY=";
  };
  sentence-transformers = pkgs.fetchPip {
    pname = "sentence-transformers";
    version = "3.3.1";
    hash = "sha256-je0mkBEGCIGi/lxOa/vM8VBdBQ+6F8qdZHe/DkkUfAU=";
  };
  transformers = pkgs.fetchPip {
    pname = "transformers";
    version = "4.47.1";
    hash = "sha256-0Y1kbOoWknstETm+WeNZnXRX4onnlKgums3Q0jOJyWs=";
  };
  huggingface-hub = pkgs.fetchPip {
    pname = "huggingface-hub";
    version = "0.27.0";
    hash = "sha256-o3RrBiYhfqf+PlFzoYNQmD0a6bsPZLIoqlmNyPFtl7Y=";
  };
  tokenizers = pkgs.fetchPip {
    pname = "tokenizers";
    version = "0.21.0";
    hash = "sha256-7kpv2eBekAUcHFBz8SQ6c2KmWofeUpCU1s1wiJnsocc=";
  };
  safetensors = pkgs.fetchPip {
    pname = "safetensors";
    version = "0.4.5";
    hash = "sha256-mHJWgIFwauFI334FcjfYQfGQFNAH3k2sX4QR6zp7/JY=";
  };
  filelock = pkgs.fetchPip {
    pname = "filelock";
    version = "3.16.1";
    hash = "sha256-GDWllDi+sBGGwKKvrzNHybkJFCpm+10dVVlwshIv9fo=";
  };
  requests = pkgs.fetchPip {
    pname = "requests";
    version = "2.32.3";
    hash = "sha256-3071zTMyJr2lxJUm2x4O6kmsRcCh0uhWjChecoH1U50=";
  };
  pyyaml = pkgs.fetchPip {
    pname = "pyyaml";
    version = "6.0.2";
    hash = "sha256-bD2ILzd8um0d+FJrbwOUnRqapE9wi9SVgT14pu6npRI=";
  };
  packaging = pkgs.fetchPip {
    pname = "packaging";
    version = "24.2";
    hash = "sha256-t1RqxEpLHJWv47OfT764mujkNYyi8kn9QrBJSScjJmg=";
  };
  torch = pkgs.fetchPip {
    pname = "torch";
    version = "2.6.0+cpu";
    hash = "sha256-6SRZg0SCc+YMIOf6V9cQ9mzNiFlxiCZ5mtQ1c0EBxxg=";
  };
}
