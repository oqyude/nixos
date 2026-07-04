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
            {
              addr = "127.0.0.1";
              port = 10000;
            }
          ];
        };
        "office.home.arpa" = {
          forceSSL = true;
          enableACME = true;
        };
        "pdf.private" = {
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
            {
              addr = "127.0.0.1";
              port = 8446;
            }
          ];
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "pdf.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:8446";
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "nextcloud.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:10000";
              proxyWebsockets = true;
            };
            "/whiteboard" = {
              proxyPass = "http://127.0.0.1:3002";
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "talk.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   # locations = {
        #   #   "/" = {
        #   #     proxyPass = "http://127.0.0.1:7880";
        #   #     proxyWebsockets = true;
        #   #   };
        #   # };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        # "turn.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://127.0.0.1:5349";
        #       proxyWebsockets = true;
        #     };
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        "ca.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9000";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "git.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "git.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "n8n.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:5678";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        "kuma.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:4001";
            proxyWebsockets = true;
          };
        };
        "flux.home.arpa" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:6061";
            proxyWebsockets = true;
          };
        };
        "immich.home.arpa" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:2283";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "calibre.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8083";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "dns.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:53";
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "glances.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:61208";
          };
        };
        "syncthing.home.arpa" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8384";
          };
        };
        # "zeroq.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
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
