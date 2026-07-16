{
  config,
  inputs,
  pkgs,
  ...
}:
let
  server = "100.64.0.0";
in
{
  # environment.etc."nginx/pubray".text = inputs.zeroq-credentials.services.xray.auth;
  users.users.nginx.extraGroups = [ "acme" ];
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      # appendHttpConfig = inputs.zeroq-credentials.services.xray.maps;
      virtualHosts = {
        # "pubray.zeroq.su" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   root = "${inputs.zeroq-credentials.services.xray.subs}";
        #   locations."/" = {
        #     extraConfig = ''
        #       auth_basic "Restricted";
        #       auth_basic_user_file /etc/nginx/pubray;

        #       if ($subfile = "") { return 403; }
        #       rewrite ^/$ $subfile break;
        #     '';
        #   };
        # };
        "x.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:2049";
              proxyWebsockets = true;
            };
            "/subs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
            "/subsjs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
            "/clash/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
          };
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
        "office.zeroq.su" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${server}:8090";
              proxyWebsockets = true;
            };
          };
          # extraConfig = ''
          #   client_max_body_size 5G;

          #   proxy_http_version 1.1;
          #   proxy_buffering off;

          #   proxy_set_header Host $host;
          #   proxy_set_header X-Forwarded-Host $host;
          #   proxy_set_header X-Forwarded-Proto $scheme;
          #   proxy_set_header X-Real-IP $remote_addr;
          #   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          #   proxy_set_header Authorization $http_authorization;

          #   proxy_set_header Upgrade $http_upgrade;
          #   proxy_set_header Connection "upgrade";
          # ''; # absolute_redirect off;
        };
        "immich.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:2283";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
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
        # "ai.zeroq.su" = {
        #   forceSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:11112";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
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
