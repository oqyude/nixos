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
        "collabora.zeroq.ru" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${server}:9980";
            proxyWebsockets = true; # collabora uses websockets
          };
        };
        "immich.zeroq.ru" = {
          # 31.57.105.253
          # listen = [
          #   {
          #     addr = "0.0.0.0";
          #     port = 80;
          #   }
          #   {
          #     addr = "0.0.0.0";
          #     port = 443;
          #     ssl = true;
          #   }
          # ];
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://${server}:2283"; # Порт Immich
              proxyWebsockets = true; # Если Immich использует WebSockets
            };
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "nextcloud.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:10000"; # Порт Nextcloud
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "flux.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:6061"; # Порт Nextcloud
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "calibre.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:8083"; # Порт Nextcloud
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
            proxyPass = "http://${server}:6060"; # Порт Nextcloud
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "llm.zeroq.ru" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://atoridu.laxta-platy.ts.net:11111"; # Порт Open WebUI
        #     proxyWebsockets = true;
        #   };
        # };
      };
    };
    # blocky = {
    #   enable = true;
    #   settings = {
    #     ports.dns = 53; # Port for incoming DNS Queries.
    #     upstreams.groups.default = [
    #       "https://dns.quad9.net/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
    #     ];
    #     # For initially solving DoH/DoT Requests when no system Resolver is available.
    #     bootstrapDns = {
    #       upstream = "https://dns.quad9.net/dns-query";
    #       ips = [ "9.9.9.9" ];
    #     };
    #     # Custom DNS entries
    #     customDNS = {
    #       mapping = {
    #         "immich.zeroq.ru" = "100.90.0.0";
    #       };
    #     };
    #   };
    # };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "go.bin043120@gmail.com";
      #webroot = "/var/lib/acme/acme-challenge";
      #group = config.services.nginx.group;
      #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      #listenHTTP = ":1360";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
