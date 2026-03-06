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
      config = {
        web = {
          "allow connections from" = "localhost netdata.local *";
          "default port" = "19999";
          "bind to" = "localhost";
        };
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    19999
  ];
}
