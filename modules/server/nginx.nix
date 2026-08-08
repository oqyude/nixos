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
        "office.zeroq.su" = {
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
        # "pdf.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://127.0.0.1:8446";
        #       proxyWebsockets = true;
        #     };
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        # "homebox.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://127.0.0.1:7745";
        #       proxyWebsockets = true;
        #     };
        #   };
        # };
        # "nextcloud.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://127.0.0.1:10000";
        #       proxyWebsockets = true;
        #     };
        #     "/whiteboard" = {
        #       proxyPass = "http://127.0.0.1:3002";
        #       proxyWebsockets = true;
        #     };
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
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
        # "ca.zeroq.su" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:9000";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        # "git.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:3000";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
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
        # "kuma.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:4001";
        #     proxyWebsockets = true;
        #   };
        # };
        # "flux.home.arpa" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:6061";
        #     proxyWebsockets = true;
        #   };
        # };
        # "navidrome.home.arpa" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:4533";
        #     proxyWebsockets = true;
        #   };
        # };
        # "immich.home.arpa" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:2283";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        "immich.zeroq.su" = {
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
        "kuma.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:4001";
            proxyWebsockets = true;
          };
        };
        "health.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:19999";
            proxyWebsockets = true;
          };
        };
        "git.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:3000";
            proxyWebsockets = true;
          };
        };
        "homebox.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:7745";
            proxyWebsockets = true;
          };
        };
        # "agent.zeroq.su" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:3000";
        #     proxyWebsockets = true;
        #   };
        # };
        # "node-red.zeroq.su" = {
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
        "zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          root = pkgs.writeTextDir "index.html" ''
            <!doctype html>
            <html>
            <body>
              <pre>What are you doing here?</pre>
            </body>
            </html>
          '';
          locations = {
            "/guest/" = {
              proxyPass = "http://${server}:80";
              proxyWebsockets = true;
            };
            # "/.well-known/discord" = {
            #   extraConfig = ''
            #     default_type text/plain;
            #     return 200 "dh=c2d103553a4cfdaa1b7952a87a7d8120a1e167cc";
            #   '';
            # };
          };
        };
        "flux.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:6061";
            proxyWebsockets = true;
          };
        };
        "navidrome.zeroq.su" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:4533";
            proxyWebsockets = true;
          };
        };
        "vetymae.opencodes.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://100.86.62.4:4096";
            proxyWebsockets = true;
          };
        };
        "lamet.opencodes.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://100.106.21.39:6061";
            proxyWebsockets = true;
          };
        };
        "n8n.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:5678";
            proxyWebsockets = true;
          };
        };
        # "office.zeroq.su" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   locations = {
        #     "/" = {
        #       proxyPass = "http://${server}:8090";
        #       proxyWebsockets = true;
        #     };
        #   };
        # };
        "nextcloud.zeroq.su" = {
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
        "calibre.zeroq.su" = {
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
        "nix-cache.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:5000";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "pdf.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:8446";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "calibre.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:8083";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        # "dns.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:53";
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        # "glances.home.arpa" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:61208";
        #   };
        # };
        # "syncthing.home.arpa" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://127.0.0.1:8384";
        #   };
        # };
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
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
