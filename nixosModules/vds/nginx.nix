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
        # "office.zeroq.ru" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   kTLS = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:8890";
        #     proxyWebsockets = true; # onlyoffice uses websockets
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #   '';
        # };
        "collabora.zeroq.ru" = {
          enableACME = true;
          forceSSL = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:8080";
            proxyWebsockets = true; # collabora uses websockets
          };
          # listen = [
          #   {
          #     addr = "0.0.0.0";
          #     port = 443;
          #     ssl = true;
          #   }
          # ];
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto https;
            client_max_body_size 5G;
          '';
        };
        "immich.zeroq.ru" = {
          # 31.57.105.253
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:2283"; # Порт Immich
            proxyWebsockets = true; # Если Immich использует WebSockets
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        "nextcloud.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
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
          kTLS = true;
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
          kTLS = true;
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
          kTLS = true;
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
