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
        global = {
          "bind to" = "netdata.local";
        };
        web = {
          "allow connections from" = "localhost netdata.local *";
          "default port" = "19999";
        };
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    19999
  ];
}
