{
  config,
  inputs,
  ...
}:
let
  server = "100.64.0.0";
in
{
  users.users.nginx.extraGroups = [ "acme" ];
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "kuma.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:4001";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "node-red.zeroq.ru" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   kTLS = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:1880";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        "flux.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:6061";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "office.zeroq.ru" = {
          enableACME = true;
          forceSSL = true;
          kTLS = true;
          locations = {
            "/" = {
              proxyPass = "http://${server}:8000"; # API и coauthoring
              proxyWebsockets = true;
            };
            "/web-apps/" = {
              proxyPass = "http://${server}:8000/web-apps/"; # фронтенд
              proxyWebsockets = true;
            };
            "/coauthoring/" = {
              proxyPass = "http://${server}:8000/coauthoring/"; # coauthoring WS
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
            proxy_set_header Host $host
          ''; # absolute_redirect off;
        };
        "immich.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:2283";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "nextcloud.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations = {
            "/" = {
              proxyPass = "http://${server}:10000";
              proxyWebsockets = true;
            };
            "/whiteboard" = {
              proxyPass = "http://${server}:3002";
              proxyWebsockets = true;
            };
            "/onlyoffice" = {
              proxyPass = "http://${server}:8000";
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "calibre.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:8083";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "pdf.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:6060";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "llm.zeroq.ru" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://100.86.62.4:11112";
        #     proxyWebsockets = true;
        #   };
        # };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "go.bin043120@gmail.com";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
