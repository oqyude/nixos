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
        "mealie.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:9000";
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
            proxyPass = "http://${server}:6061";
            proxyWebsockets = true;
          };
          extraConfig = ''
            client_max_body_size 5G;
          '';
        };
        # "office.zeroq.ru" = {
        #   enableACME = true;
        #   forceSSL = true;
        #   kTLS = true;
        #   locations."/" = {
        #     proxyPass = "http://${server}:8080";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     client_max_body_size 5G;
        #     absolute_redirect off;
        #   '';
        # };
        "immich.zeroq.ru" = {
          forceSSL = true;
          enableACME = true;
          kTLS = true;
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
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:10000";
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
          kTLS = true;
          locations."/" = {
            proxyPass = "http://${server}:6060";
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
        #     proxyPass = "http://atoridu.laxta-platy.ts.net:11111";
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
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
