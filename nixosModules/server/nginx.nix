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
        "localhost:10000" = {
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
        # "trilium" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   listen = [
        #     {
        #       addr = "100.64.0.0";
        #       port = 11000;
        #     }
        #     {
        #       addr = "192.168.1.20";
        #       port = 11000;
        #     }
        #   ];
        # };
        "onlyoffice.local" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "100.64.0.0";
              port = 8000;
            }
            {
              addr = "192.168.1.20";
              port = 8000;
            }
          ];
          extraConfig = ''
            # Force nginx to return relative redirects. This lets the browser
            # figure out the full URL. This ends up working better because it's in
            # front of the reverse proxy and has the right protocol, hostname & port.
            absolute_redirect off;
          '';
        };
        # "localhost:9980" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   listen = [
        #     {
        #       addr = "100.64.0.0";
        #       port = 9980;
        #     }
        #     {
        #       addr = "192.168.1.20";
        #       port = 9980;
        #     }
        #   ];
        # };
        # "localhost:5230" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   listen = [
        #     {
        #       addr = "100.64.0.0";
        #       port = 5230;
        #     }
        #     {
        #       addr = "192.168.1.20";
        #       port = 5230;
        #     }
        #   ];
        # };
      };
    };
  };
}
