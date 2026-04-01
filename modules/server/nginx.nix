{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  server = "192.168.1.20";
in
{
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "nextcloud-private.local" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "100.64.0.0";
              port = 10000;
            }
            {
              addr = "192.168.1.20";
              port = 10000;
            }
          ];
        };
        "nextcloud.local" = {
          forceSSL = false;
          enableACME = false;
          locations = {
            "/" = {
              proxyPass = "http://${server}:10000";
              proxyWebsockets = true;
            };
            "/whiteboard" = {
              proxyPass = "http://${server}:3002";
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "n8n.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:5678";
            proxyWebsockets = true;
          };
        };
        "kuma.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:4001";
            proxyWebsockets = true;
          };
        };
        "health.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:19999";
            proxyWebsockets = true;
          };
        };
        "agent.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:3000";
            proxyWebsockets = true;
          };
        };
        "flux.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:6061";
            proxyWebsockets = true;
          };
        };
        "immich.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:2283";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        #         "office.local" = {
        #           enableACME = false;
        #           forceSSL = false;
        #           locations = {
        #             "/" = {
        #               proxyPass = "http://${server}:8000"; # 9980
        #               proxyWebsockets = true;
        #             };
        #           };
        #           extraConfig = ''
        #             client_max_body_size 5G;
        #             proxy_set_header X-Forwarded-Proto $scheme;
        #             proxy_set_header X-Real-IP $remote_addr;
        #             proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #           ''; # absolute_redirect off;
        #         };
        "calibre.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:8083";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "zeroq.local" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   root = pkgs.writeTextDir "index.html" ''
        #     <!doctype html>
        #     <html>
        #     <body>
        #       <pre>This server is running in backend.</pre>
        #     </body>
        #     </html>
        #   '';
        #   listen = [
        #     {
        #       addr = "100.64.0.0";
        #       port = 80;
        #     }
        #     {
        #       addr = "192.168.1.20";
        #       port = 80;
        #     }
        #   ];
        # };
      };
    };
  };
}
