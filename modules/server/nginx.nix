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
              proxyPass = "http://${server}:8446";
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
        "ca.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:9000";
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
            proxyPass = "http://${server}:3000";
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
            proxyPass = "http://${server}:4001";
            proxyWebsockets = true;
          };
        };
        "flux.home.arpa" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:6061";
            proxyWebsockets = true;
          };
        };
        "immich.home.arpa" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:2283";
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
            proxyPass = "http://${server}:8083";
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
            proxyPass = "http://${server}:53";
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "zeroq.home.arpa" = {
          forceSSL = true;
          enableACME = true;
          root = pkgs.writeTextDir "index.html" ''
            <!doctype html>
            <html>
            <body>
              <pre>This server is running in backend.</pre>
            </body>
            </html>
          '';
          listen = [
            {
              addr = "100.64.0.0";
              port = 80;
            }
            {
              addr = "192.168.1.20";
              port = 80;
            }
          ];
        };
      };
    };
  };
  security = {
    acme = {
      acceptTerms = true;
      defaults = {
        email = "oqyude@zeroq.su";
        server = "https://localhost:9000/acme/acme/directory";
        dnsProvider = null;
      };
    };
  };
}
