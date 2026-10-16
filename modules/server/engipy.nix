{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# engipy — FastAPI + SBERT webapp для подбора ГЭСН по ВОР.
#
# Композиция:
#   - systemd unit `engipy` запускает uvicorn на 127.0.0.1:<port>
#     (см. ExecStart ниже). Python-окружение — `cfg.pythonPackage`,
#     обычно `pkgs.python311.withPackages (ps: with ps; [ fastapi
#     uvicorn pydantic pydantic-settings sqlalchemy numpy
#     sentence-transformers torch ])`.
#   - nginx проксирует `engipy.zeroq.su/api/` на uvicorn и
#     раздаёт собранную Vite-статику из ${dataDir}/web напрямую
#     (vhost см. в modules/server/nginx.nix).
#   - Authelia SSO уже подключена через `auth_request /authelia`
#     + 401→302 redirect на login — wildcard `*.zeroq.su → one_factor`
#     в modules/server/authelia.nix покрывает новый vhost без правок.
#
# Storage (R1.2 в .agent/rules/project-rules.md):
#   SQLite-БД (`fsnb_sbornik.db`) и SBERT-эмбеддинги (`*.npy`) лежат
#   на External через bind-mount /mnt/services/engipy → /var/lib/engipy.
#   Старт uvicorn зависит от /var/lib/engipy.mount (`requires = [...]`),
#   что заменяет нерабочий mkStorageGuard. Если External не подмонтирован
#   на этапе systemd-mounts — bind-mount всё равно сработает на пустой
#   target внутри `/mnt/services/` (которая сама bind-mount на External —
#   см. mkServiceStorage в lib/xlib/helpers.nix).
#
# dataDir (/var/lib/engipy) должен содержать после деплоя:
#   web/index.html, web/assets/...    — после `npm run build`
#   fsnb_sbornik.db                   — SQLite (см. ENGIPY_DB_PATH)
#   gesn_cointegrated_rubert_tiny2.npy
#   gesn_cointegrated_rubert_tiny2_codes.npy
#
# nginx (юзер `nginx`, группа `nginx`) читает ${dataDir}/web напрямую;
# этому помогает `users.users.nginx.extraGroups = [ cfg.user ]` ниже —
# bind-mount создаётся с mode 0750 ${user}:${user}, и traverse-bit на
# родителе есть только у группы.
let
  cfg = config.host.engipy;

  # Bind-mount External/Services/engipy → /var/lib/engipy (0750 engipy:engipy).
  storage = xlib.helpers.mkServiceStorage {
    name = "engipy";
    user = cfg.user;
    group = cfg.user;
    mode = "0750";
  };

  # Имя mount-юнита, который генерит mkSystemdBind (см. helpers.nix:53-65).
  # systemd-escape("/var/lib/engipy") → "var-lib-engipy.mount".
  storageMountUnit = "var-lib-engipy.mount";
in
{
  options.host.engipy = {
    enable = lib.mkEnableOption "engipy webapp (uvicorn + FastAPI за nginx)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Порт, на котором слушает uvicorn (loopback, за nginx).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "engipy";
      description = "Системный пользователь, от которого запускается uvicorn (и группа).";
    };

    pythonPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python311;
      description = ''
        Python с зависимостями (fastapi, uvicorn, pydantic, sqlalchemy,
        numpy, sentence-transformers, torch). Обычно
        `pkgs.python311.withPackages (ps: with ps; [ ... ])`.
      '';
    };

    dbFileName = lib.mkOption {
      type = lib.types.str;
      default = "fsnb_sbornik.db";
      description = "Имя SQLite-БД в ${storage.target}. Прокидывается как ENGIPY_DB_PATH.";
    };

    embeddingsStem = lib.mkOption {
      type = lib.types.str;
      default = "gesn_cointegrated_rubert_tiny2";
      description = ''
        Stem эмбеддингов в ${storage.target}: <stem>.npy + <stem>_codes.npy.
        Прокидывается как ENGIPY_EMBEDDINGS_PATH.
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "cointegrated/rubert-tiny2";
      description = ''
        Имя SBERT-модели из HuggingFace. Должно совпадать с моделью,
        под которую посчитаны embeddingsStem.npy + _codes.npy.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = storage.systemd;

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      # Home = storage target (bind-mount из External). createHome = false,
      # потому что каталог создаёт tmpfiles + bind-mount, а не NixOS-Users.
      home = storage.target;
      createHome = false;
      shell = lib.mkDefault "${pkgs.bash}/bin/bash";
      description = "engipy webapp service account";
    };
    users.groups.${cfg.user} = { };

    # nginx (в ${storage.target}/web читает статику Vite-бандла) берём
    # в группу ${cfg.user}, чтобы пройти traverse-bit на 0750 родителе.
    users.users.nginx.extraGroups = [ cfg.user ];

    environment.systemPackages = [ cfg.pythonPackage ];

    systemd.services.engipy = {
      description = "engipy webapp (uvicorn)";
      documentation = [ "https://github.com/oqyude/engipy" ];
      wantedBy = [ "multi-user.target" ];

      after = [
        "network-online.target"
        storageMountUnit
      ];
      wants = [ "network-online.target" ];
      # requires гарантирует, что bind-mount поднялся ДО старта uvicorn
      # (без него uvicorn попытается писать БД в tmpfs под bind-mount).
      requires = [ storageMountUnit ];

      environment = {
        PYTHONUNBUFFERED = "1";
        PYTHONDONTWRITEBYTECODE = "1";
        # sitePackages-путь выбранного pythonPackage нужен, чтобы
        # uvicorn находился в PATH внутри sandbox (ExecStart использует
        # абсолютный путь, но pydantic-settings/sentence-transformers
        # могут подтягивать другие entry-points из site-packages).
        PYTHONPATH = "${cfg.pythonPackage}/${cfg.pythonPackage.sitePackages}";
        ENGIPY_DB_PATH = "${storage.target}/${cfg.dbFileName}";
        ENGIPY_EMBEDDINGS_PATH = "${storage.target}/${cfg.embeddingsStem}.npy";
        ENGIPY_DATA_DIR = storage.target;
        ENGIPY_MODEL = cfg.model;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = storage.target;
        ExecStart = "${cfg.pythonPackage}/bin/python -m uvicorn app.main:app"
          + " --host 127.0.0.1 --port ${toString cfg.port} --no-access-log";
        Restart = "on-failure";
        RestartSec = "5s";

        # Sandbox. uvicorn пишет только в storage.target (БД, .vite cache,
        # logs); web/ под ним читается nginx (см. users.users.nginx.extraGroups).
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [ storage.target ];
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
