{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  services = {
    netdata = {
      enable = true;
      package = pkgs.netdata.override {
        withCloudUi = true;
      };
      config = {
        web = {
          "allow connections from" = "localhost *";
          "default port" = "19999";
          "bind to" = "0.0.0.0";
        };
      };
      python = {
        enable = true;
        recommendedPythonPackages = true;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    19999
  ];
}
