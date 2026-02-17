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
  environment.etc."nginx/pubray".text = inputs.zeroq-credentials.services.xray.auth;
  users.users.nginx.extraGroups = [ "acme" ];
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      appendHttpConfig = inputs.zeroq-credentials.services.xray.maps;
      virtualHosts = {
        "pubray.zeroq.ru" = {
          enableACME = true;
          forceSSL = true;
          root = "${inputs.zeroq-credentials.services.xray.subs}";
          locations."/" = {
            extraConfig = ''
              auth_basic "Restricted";
              auth_basic_user_file /etc/nginx/pubray;

              if ($subfile = "") { return 403; }
              rewrite ^/$ $subfile break;
            '';
          };
        };
        "x.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:2053";
              proxyWebsockets = true;
            };
            "/subs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
          };
        };
        "kuma.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
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
        "zeroq.ru" = {
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
        "flux.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
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
          locations = {
            "/" = {
              proxyPass = "http://${server}:9980"; # API и coauthoring
              proxyWebsockets = true;
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          ''; # absolute_redirect off;
        };
        "immich.zeroq.ru" = {
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
        "nextcloud.zeroq.ru" = {
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
        "calibre.zeroq.ru" = {
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
        "pdf.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:6060";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "ai.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:11112";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
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
