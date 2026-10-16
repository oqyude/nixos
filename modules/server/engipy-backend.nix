{
  config,
  lib,
  pkgs,
  ...
}:
# engipy — backend (uvicorn) для rydiwo.
#
# Sapphira (см. engipy-frontend.nix) держит nginx vhost и проксирует
# /api/* на этот хост. Здесь крутится uvicorn с полным ML-стеком:
# FastAPI + uvicorn + sentence-transformers + torch. SQLite-БД и SBERT-
# эмбеддинги лежат в /var/lib/engipy на rydiwo NVMe (62 GB свободно);
# bind-mount не нужен — rydiwo не имеет External-storage (device: secondary),
# данные просто в /var/lib/engipy.
#
# pythonPackage строится через fetchPip из requirements.nix — только wheels
# с PyPI, никаких часовых компиляций на 4 ядрах rydiwo. requirements.nix
# сгенерирован локально через WSL nixos (pip download + nix hash path),
# поэтому hash'и — реальные SRI sha256, а не lib.fakeSha256.
#
# Workflow:
#   1. cd /etc/nixos && git pull
#   2. sudo nixos-rebuild switch --flake /etc/nixos#rydiwo
#   3. scp app/ fsnb_sbornik.db gesn_*.npy → rydiwo:/var/lib/engipy/
#   4. sudo systemctl enable --now engipy
#   5. sudo journalctl -u engipy -f
#
# На sapphira:
#   1. cd /etc/nixos && git pull
#   2. sudo nixos-rebuild switch --flake /etc/nixos#sapphira
#   3. scp dist/ → sapphira:/var/lib/engipy/web/
#   4. sudo nginx -t && sudo systemctl reload nginx
let
  cfg = config.host.engipy-backend;
in
{
  options.host.engipy-backend = {
    enable = lib.mkEnableOption ''
      engipy backend: поднять uvicorn под systemd unit `engipy` на этом
      хосте (rydiwo-стиль: FastAPI + ML + DB).
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

    pythonPackage = lib.mkOption {
      type = lib.types.package;
      description = ''
        Python-окружение с ML-стеком. По умолчанию собирается через
        fetchPip из ./requirements.nix (wheels с PyPI, без компиляции).
        Можно переопределить на любой другой derivation с тем же API.
      '';
      default = let
        reqs = import ./requirements.nix { inherit pkgs; };
      in pkgs.python311.buildEnv {
        extraLibs = builtins.attrValues reqs;
        ignoreCollisions = true;
      };
      defaultText = lib.literalExpression ''
        let reqs = import ./requirements.nix { inherit pkgs; };
        in pkgs.python311.buildEnv {
          extraLibs = builtins.attrValues reqs;
          ignoreCollisions = true;
        }
      '';
    };

    dbFileName = lib.mkOption {
      type = lib.types.str;
      default = "fsnb_sbornik.db";
      description = "Имя SQLite-БД в dataDir. Прокидывается как ENGIPY_DB_PATH.";
    };

    embeddingsStem = lib.mkOption {
      type = lib.types.str;
      default = "gesn_cointegrated_rubert_tiny2";
      description = ''
        Stem эмбеддингов в dataDir: <stem>.npy + <stem>_codes.npy.
        Прокидывается как ENGIPY_EMBEDDINGS_PATH.
      '';
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
        Рабочий каталог uvicorn: app/, SQLite-БД, SBERT-эмбеддинги,
        HuggingFace-кэш моделей. На rydiwo это обычный каталог на NVMe,
        без bind-mount (R1.2 применим только к device: server / External).
      '';
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = ''
        Адрес, на котором uvicorn слушает. По умолчанию 0.0.0.0 — потому
        что sapphira ходит по LAN (не loopback). Если хочется только
        loopback — установите "127.0.0.1" и защитите firewall'ом.
      '';
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
      # dataDir — корневой каталог, mode 0750 engipy:engipy.
      # uvicorn пишет в этот каталог (БД, .vite cache, HF cache),
      # ничего больше в /var/lib/engipy не пишется.
      "Z ${cfg.dataDir} 0750 ${cfg.user} ${cfg.user} - -"
    ];

    systemd.services.engipy = {
      description = "engipy webapp (uvicorn + FastAPI за nginx)";
      documentation = [ "https://github.com/oqyude/engipy" ];
      wantedBy = [ "multi-user.target" ];

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        PYTHONUNBUFFERED = "1";
        PYTHONDONTWRITEBYTECODE = "1";
        # PYTHONPATH указывает на site-packages выбранного pythonPackage.
        # Нужно для uvicorn entry-points (sentence-transformers,
        # transformers, pydantic-settings) внутри sandbox.
        PYTHONPATH = "${cfg.pythonPackage}/${cfg.pythonPackage.sitePackages}";
        # libgomp/openblas нужны torch CPU-wheel'у — пробрасываем через
        # LD_LIBRARY_PATH. Иначе при первом импорте torch упадёт с
        # ImportError: libgomp.so.1 / libopenblas.so.0.
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.openblas
        ];
        ENGIPY_DB_PATH = "${cfg.dataDir}/${cfg.dbFileName}";
        ENGIPY_EMBEDDINGS_PATH = "${cfg.dataDir}/${cfg.embeddingsStem}.npy";
        ENGIPY_DATA_DIR = cfg.dataDir;
        ENGIPY_MODEL = cfg.model;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.pythonPackage}/bin/python -m uvicorn app.main:app"
          + " --host ${cfg.bindAddress} --port ${toString cfg.port} --no-access-log";
        Restart = "on-failure";
        RestartSec = "5s";

        # Sandbox. uvicorn пишет только в cfg.dataDir (БД, .vite cache,
        # HF кэш моделей в ~/.cache/huggingface/). ReadWritePaths
        # разрешает запись только туда — ProtectHome/ProtectSystem
        # ограничивают остальное read-only.
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
