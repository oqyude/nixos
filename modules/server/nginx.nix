{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  server = "192.168.1.20";

  # Standard TLS proxy vhost: "/" -> http://server:port
  # Returns { name = domain; value = vhost; } for builtins.listToAttrs
  mkProxy =
    {
      domain,
      port,
      addSSL ? false,
      body ? false,
    }:
    {
      name = domain;
      value = {
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${server}:${toString port}";
          proxyWebsockets = true;
        };
      }
      // lib.optionalAttrs (!addSSL) { forceSSL = true; }
      // lib.optionalAttrs addSSL { addSSL = true; }
      // lib.optionalAttrs body {
        extraConfig = ''
          client_max_body_size 5G;
        '';
      };
    };

  # Simple proxy sites
  sites = [
    {
      domain = "immich.zeroq.su";
      port = 2283;
      addSSL = true;
      body = true;
    }
    {
      domain = "kuma.zeroq.su";
      port = 4001;
    }
    {
      domain = "health.zeroq.su";
      port = 19999;
    }
    {
      domain = "git.zeroq.su";
      port = 3000;
    }
    {
      domain = "homebox.zeroq.su";
      port = 7745;
    }
    {
      domain = "flux.zeroq.su";
      port = 6061;
    }
    {
      domain = "navidrome.zeroq.su";
      port = 4533;
      addSSL = true;
    }
    {
      domain = "calibre.zeroq.su";
      port = 8083;
      body = true;
    }
    # {
    #   domain = "mc.zeroq.su";
    #   port = 25565;
    # }
    {
      domain = "nix-cache.zeroq.su";
      port = 5000;
      body = true;
    }
    {
      domain = "pdf.zeroq.su";
      port = 8446;
      body = true;
    }
  ];
in
{
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = (builtins.listToAttrs (map mkProxy sites)) // {
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
        "x.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://${server}:2049";
              proxyWebsockets = true;
            };
            "/subs/" = {
              proxyPass = "http://${server}:2096";
              proxyWebsockets = true;
            };
            "/subsjs/" = {
              proxyPass = "http://${server}:2096";
              proxyWebsockets = true;
            };
            "/clash/" = {
              proxyPass = "http://${server}:2096";
              proxyWebsockets = true;
            };
          };
        };
        # "talk.zeroq.su" = {
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
        # "turn.zeroq.su" = {
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
        # "ca.home.arpa" = {
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
        # "n8n.zeroq.su" = {
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
        # "n8n.zeroq.su" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:5678";
        #     proxyWebsockets = true;
        #   };
        # };
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
