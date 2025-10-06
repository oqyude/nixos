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
        "nextcloud.local" = {
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
        # "office.zeroq.ru" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   locations."/" = {
        #     proxyPass = "http://onlyoffice.local:8000";
        #     proxyWebsockets = true;
        #   };
        #   extraConfig = ''
        #     # Force nginx to return relative redirects. This lets the browser
        #     # figure out the full URL. This ends up working better because it's in
        #     # front of the reverse proxy and has the right protocol, hostname & port.
        #     absolute_redirect off;
        #   '';
        # };
      };
    };
  };
}
