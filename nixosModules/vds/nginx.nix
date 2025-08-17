{
  config,
  ...
}:
let
  server = "100.64.0.0";
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
        "immich.zeroq.ru" = {
          # 31.57.105.253
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:2283"; # Порт Immich
            proxyWebsockets = true; # Если Immich использует WebSockets
          };
          locations."/.well-known/acme-challenge/" = {
            root = "/var/lib/acme/acme-challenge";
            tryFiles = "$uri $uri/ =404";
          };
        };
        "nextcloud.zeroq.ru" = {
          addSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:10000"; # Порт Nextcloud
            proxyWebsockets = true;
          };
          locations."/.well-known/acme-challenge/" = {
            root = "/var/lib/acme/acme-challenge";
            tryFiles = "$uri $uri/ =404";
          };
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
    defaults.email = "oqyude@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
