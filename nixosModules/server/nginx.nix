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
        "trilium" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "100.64.0.0";
              port = 11000;
            }
            {
              addr = "192.168.1.20";
              port = 11000;
            }
            # {
            #   addr = "0.0.0.0";
            #   port = 80;
            # }
            # {
            #   addr = "0.0.0.0";
            #   port = 443;
            # }
          ];
        };
        # "onlyoffice" = {
        #   forceSSL = false;
        #   enableACME = false;
        #   listen = [
        #     {
        #       addr = "100.64.0.0";
        #       port = 8080;
        #     }
        #     {
        #       addr = "192.168.1.20";
        #       port = 8080;
        #     }
        #   ];
        # };
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
