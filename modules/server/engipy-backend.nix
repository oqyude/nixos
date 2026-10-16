{
  config,
  lib,
  pkgs,
  ...
}:
# engipy — backend (uvicorn) для rydiwo.
#
# Sapphira (см. engipy-frontend.nix) держит nginx vhost и проксирует
# /api/* на этот хост. Здесь крутится uvicorn с полным ML-стеком.
#
# Подход к Python-окружению: pip-based venv, не Nix-built.
# Раньше пробовал `pkgs.fetchPypi { ... }` через `python311.withPackages`
# и `python311.buildEnv.override { ... }` — оба НЕ раскладывают wheels
# в site-packages (env оказывается пустой: только базовые файлы python3).
# Pip-venv тривиально решает эту проблему:
#   python -m venv /var/lib/engipy/venv
#   pip install -r requirements.txt + torch from pytorch.org
#
# Минусы подхода:
#   - Окружение reproducible только если requirements.txt зафиксирован
#     версиями (не ломается ниже).
# Плюсы:
#   - Работает с любыми wheels из PyPI / pytorch.org без сложной логики.
#   - rydiwo сам сделает pip install при первом systemd ExecStartPre.
#   - Никаких часовых сборок torch на rydiwo (как это было на sapphira).
#
# Workflow:
#   1. На rydiwo: cd /etc/nixos && git pull
#   2. sudo nixos-rebuild switch --flake /etc/nixos#rydiwo
#   3. sudo systemctl restart engipy   (ExecStartPre создаст venv ~5 мин)
#   4. sudo journalctl -u engipy -f      (смотреть прогресс)
let
  cfg = config.host.engipy-backend;

  # requirements.txt с pinned versions. --extra-index-url ставит
  # pytorch.org/whl/cpu как дополнительный источник — torch==2.6.0+cpu
  # находится ТОЛЬКО там (на PyPI лежит только universal-версия,
  # требующая CUDA ~3 GB). Поэтому sentence-transformers (тянет
  # torch>=1.11.0) подхватит CPU-wheel автоматически, без отдельного
  # upgrade-шага.
  #
  # Полный список должен покрывать ВСЁ, что import'ит app/ при
  # uvicorn'овском boot (`import app.main` грузит всю иерархию
  # app.main → app.routes.match → app.matchers → pandas/numpy/sbert).
  requirementsTxt = pkgs.writeText "engipy-requirements.txt" ''
    fastapi==0.115.6
    uvicorn[standard]==0.32.0
    pydantic==2.10.3
    pydantic-settings==2.7.0
    structlog==24.4.0
    sqlalchemy==2.0.36
    numpy==2.2.1
    pandas==2.3.3
    openpyxl==3.1.5
    python-multipart==0.0.20
    sentence-transformers==3.3.1
    transformers==4.47.1
    huggingface-hub==0.27.0
    tokenizers==0.21.0
    safetensors==0.4.5
    filelock==3.16.1
    requests==2.32.3
    PyYAML==6.0.2
    packaging==24.2
    python-dotenv==1.0.1
    --extra-index-url https://download.pytorch.org/whl/cpu
    torch==2.6.0+cpu
  '';

  # Install-script (ExecStartPre). Создаёт venv и ставит wheels.
  installScript = pkgs.writeShellScriptBin "engipy-install" ''
    set -e
    cd ${cfg.dataDir}

    if [ ! -f venv/.engipy-venv-installed ]; then
      echo "[engipy-install] creating venv…"
      ${pkgs.python311}/bin/python -m venv venv

      echo "[engipy-install] installing wheels (this takes ~2-3 min)…"
      ./venv/bin/pip install --no-cache-dir -r ${requirementsTxt}

      touch venv/.engipy-venv-installed
      echo "[engipy-install] done."
    fi
  '';

  # Python binary, который мы будем использовать для venv (через
  # lib.makeBinPath). Окружение целиком — venv, $PATH не критичен.
  python = pkgs.python311;
  binPath = lib.makeBinPath [ python ];
in
{
  options.host.engipy-backend = {
    enable = lib.mkEnableOption ''
      engipy backend: поднять uvicorn под systemd unit `engipy` на этом
      хосте (rydiwo-стиль: FastAPI + ML + DB через pip-venv).
    '';

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Порт, на котором слушает uvicorn (loopback или LAN).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "engipy";
      description = "Системный пользователь, от которого запускается uvicorn.";
    };

    dbFileName = lib.mkOption {
      type = lib.types.str;
      default = "fsnb_sbornik.db";
      description = "Имя SQLite-БД в dataDir. Прокидывается как ENGIPY_DB_PATH.";
    };

    embeddingsStem = lib.mkOption {
      type = lib.types.str;
      default = "gesn_cointegrated_rubert_tiny2";
      description = "Stem эмбеддингов в dataDir.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "cointegrated/rubert-tiny2";
      description = "Имя SBERT-модели из HuggingFace.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/engipy";
      description = ''
        Рабочий каталог uvicorn: app/, venv/, SQLite-БД, SBERT-эмбеддинги,
        HuggingFace-кэш моделей.
      '';
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Адрес, на котором uvicorn слушает.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.dataDir;
      createHome = true;
      shell = lib.mkDefault "${pkgs.bash}/bin/bash";
      description = "engipy webapp service account (uvicorn + ML)";
    };
    users.groups.${cfg.user} = { };

    systemd.tmpfiles.rules = [
      "Z ${cfg.dataDir} 0750 ${cfg.user} ${cfg.user} - -"
    ];

    systemd.services.engipy-install = {
      description = "engipy venv bootstrap (pip install wheels)";
      documentation = [ "https://github.com/oqyude/engipy" ];
      wantedBy = [ "engipy.service" ];
      before = [ "engipy.service" ];

      # Запускается один раз (маркер .engipy-venv-installed в скрипте).
      # Запускать после того, как данные (app/, *.db, *.npy) уже
      # на месте — но до первого старта uvicorn.
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # environment: PATH не выставляем — системный PATH systemd'а
      # по умолчанию включает /nix/store/.../*/bin (coreutils и др.),
      # а venv-скрипт запускается по абсолютному пути
      # ${installScript}/bin/engipy-install, который всё равно
      # вызывает pip через ./venv/bin/pip. Так что PATH не критичен.

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${installScript}/bin/engipy-install";
      };
    };

    systemd.services.engipy = {
      description = "engipy webapp (uvicorn + FastAPI за nginx)";
      documentation = [ "https://github.com/oqyude/engipy" ];
      wantedBy = [ "multi-user.target" ];

      after = [ "network-online.target" "engipy-install.service" ];
      wants = [ "network-online.target" ];
      requires = [ "engipy-install.service" ];

environment = {
        PYTHONUNBUFFERED = "1";
        PYTHONDONTWRITEBYTECODE = "1";
        VIRTUAL_ENV = "${cfg.dataDir}/venv";
        # uvicorn не добавляет cwd в sys.path — WorkingDirectory не
        # достаточно. Без PYTHONPATH=cfg.dataDir получаем
        # `ModuleNotFoundError: No module named 'app'`.
        PYTHONPATH = "${cfg.dataDir}";
        ENGIPY_DB_PATH = "${cfg.dataDir}/${cfg.dbFileName}";
        ENGIPY_EMBEDDINGS_PATH = "${cfg.dataDir}/${cfg.embeddingsStem}.npy";
        ENGIPY_DATA_DIR = cfg.dataDir;
        ENGIPY_MODEL = cfg.model;
        # LD_LIBRARY_PATH указывает на /run/current-system/sw/share/nix-ld/lib —
        # это nix-ld "overrides directory" с симлинками на 64-bit системные
        # lib'ы (libstdc++, libz, libdl, libgcc_s, libpthread, libc, …).
        # Без этого path numpy._multiarray_umath.so не находит libstdc++/libz
        # и uvicorn падает на старте с 'Error importing numpy: you should not
        # try to import numpy from its source directory'. Раньше мы тянули
        # pkgs.stdenv.cc.cc.lib + openblas, но они:
        # 1) конфликтовали с torch-internal OpenMP при SBERT forward
        #    (RuntimeError: could not create a primitive в GELU activation);
        # 2) при смене на ONNX runtime они не нужны — onnxruntime поставляет
        #    свои bundled deps.
        # nix-ld lib-симлинки (это фиксированный путь на NixOS) решает обе
        # проблемы.
        LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
        # Однопоточный BLAS/OpenMP — для совместимости с onnxruntime
        # (без этого openblas+onnx могут захлебнуться на 4 cores).
        OMP_NUM_THREADS = "1";
        OPENBLAS_NUM_THREADS = "1";
        TOKENIZERS_PARALLELISM = "false";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.dataDir}/venv/bin/uvicorn --factory app.main:create_app"
          + " --host ${cfg.bindAddress} --port ${toString cfg.port} --no-access-log";
        Restart = "on-failure";
        RestartSec = "5s";

        # Sandbox.
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ cfg.dataDir ];
        LimitNOFILE = 65536;

        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        LockPersonality = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      };
    };
  };
}
