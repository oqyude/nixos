{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
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
          forceSSL = true; # Принудительный HTTPS
          enableACME = false;
          locations."/" = {
            proxyPass = "http://sapphira.laxta-platy.ts.net:2283"; # Порт Immich
            proxyWebsockets = true; # Если Immich использует WebSockets
          };
        };
        "nextcloud.zeroq.ru" = {
          forceSSL = true;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://sapphira.laxta-platy.ts.net:10000"; # Порт Nextcloud
            proxyWebsockets = true;
          };
        };
        "llm.zeroq.ru" = {
          forceSSL = true;
          enableACME = false;
          locations."/" = {
            proxyPass = "http://sapphira.laxta-platy.ts.net:11111"; # Порт Open WebUI
            proxyWebsockets = true;
          };
        };
      };
    };
  };
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "oqyude@gmail.com";
  # };
  networking.firewall.allowedTCPPorts = [
    #44443
    #44444
    80
    443
  ];
}
