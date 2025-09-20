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
        "onlyoffice" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "100.64.0.0";
              port = 8080;
            }
            {
              addr = "192.168.1.20";
              port = 8080;
            }
          ];
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
      };
    };
  };
}
