{
  config,
  lib,
  ...
}:
# engipy — frontend-only nginx vhost для sapphira.
#
# Sapphira НЕ запускает uvicorn и не держит ML-стек (2 cores, 5.6 GB RAM —
# не вытянет torch/sentence-transformers без свопа). Этот модуль
# добавляет только nginx vhost `engipy.zeroq.su`:
#
#   • /api/*  → proxyPass на rydiwo:8000 (где крутится uvicorn+ML по
#              host.engipy-backend.enable из engipy-backend.nix)
#   • /       → статика Vite-бандла из ${dataDir}/web (sapphira раздаёт
#              напрямую, без Python, чтобы не гонять большие JS через
#              прокси)
#   • /authelia → internal forward-auth, как у vtimeline.zeroq.su
#                (через authelia.zeroq.su wildcard *.zeroq.su →
#                one_factor)
#
# Backend полный на rydiwo: systemd.engipy + python311 с fetchPip +
# sentence-transformers + torch живут в engipy-backend.nix и импортируются
# только в configurations/mini-laptop.nix.
#
# Что ещё нужно сделать руками перед запуском vhost'а:
#   • залить ${dataDir}/web = собранный Vite-бандл (index.html + assets/)
#   • DNS на engipy.zeroq.su → <sapphira_ip> (A-запись)
#   • Authelia wildcard уже покрывает — менять ничего не надо
let
  cfg = config.host.engipy-frontend;
in
{
  options.host.engipy-frontend = {
    enable = lib.mkEnableOption ''
      engipy frontend: добавить vhost engipy.zeroq.su на этом хосте
      (sapphira-стиль: nginx отдаёт статику, /api/* проксируется на бэкенд).
    '';

    domain = lib.mkOption {
      type = lib.types.str;
      default = "engipy.zeroq.su";
      description = "Домен для vhost.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/engipy";
      description = ''
        Каталог, в котором лежит собранный фронт (`$dataDir/web`).
        Используется ТОЛЬКО для статической раздачи — bind-mount и
        External здесь не нужны, фронт кладётся прямо через `scp`.
      '';
    };

    backendHost = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.102";
      example = "rydiwo.lan";
      description = ''
        Хост, где крутится uvicorn (engipy-backend). По умолчанию
        rydiwo — 192.168.1.102 в LAN. По этому адресу nginx проксирует
        /api/* внутри vhost'а.
      '';
    };

    backendPort = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Порт, на котором слушает uvicorn на бэкенде.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Каталог для статики. mode 0755 root:root — nginx (юзер `nginx`)
    # читает напрямую без extra-groups; bind-mount не нужен, потому
    # что фронт мы кладём через scp, без External-storage.
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/web 0755 nginx nginx - -"
    ];

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;

      locations = {
        # /api/* → uvicorn на rydiwo. Authelia forward-auth + 401→302
        # как у vtimeline.zeroq.su (см. комментарии в nginx.nix — почему
        # именно Accept: application/json нужен).
        "/api/" = {
          proxyPass = "http://${cfg.backendHost}:${toString cfg.backendPort}";
          proxyWebsockets = true;
          extraConfig = ''
            auth_request /authelia;
            auth_request_set $authelia_user $upstream_http_remote_user;
            error_page 401 =302 https://authelia.zeroq.su/?rd=$scheme://$host$request_uri;
            client_max_body_size 50m;
            proxy_read_timeout 120s;
            proxy_send_timeout 120s;
          '';
        };
        # Vite-бандл раздаётся напрямую nginx'ом. SAP-fallback на
        # index.html нужен для client-side routing (React Router
        # History API).
        "/" = {
          root = "${cfg.dataDir}/web";
          tryFiles = "$uri $uri/ /index.html";
          index = "index.html";
          extraConfig = ''
            auth_request /authelia;
            auth_request_set $authelia_user $upstream_http_remote_user;
            error_page 401 =302 https://authelia.zeroq.su/?rd=$scheme://$host$request_uri;
          '';
        };
        # Forward-auth endpoint для /authelia sub-request.
        "= /authelia" = {
          extraConfig = ''
            internal;
            proxy_pass http://127.0.0.1:9091/api/authz/forward-auth;
            proxy_set_header X-Original-URL $request_uri;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Method $request_method;
            proxy_set_header X-Forwarded-Uri $request_uri;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Accept "application/json";
          '';
        };
      };
    };
  };
}
