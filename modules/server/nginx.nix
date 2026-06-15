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
        "nextcloud.private" = {
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
        "office.local" = {
          forceSSL = false;
          enableACME = false;
        };
        "bentopdf.local" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
            {
              addr = "100.64.0.0";
              port = 8446;
            }
            {
              addr = "192.168.1.20";
              port = 8446;
            }
          ];
          extraConfig = ''
            client_max_body_size 5G;
          '';
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
        "gitea.local" = {
          forceSSL = false;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://${server}:3000";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "nextcloud.zeroq.su" = {
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
          extraConfig = ''
            client_max_body_size 5G;
          '';
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
