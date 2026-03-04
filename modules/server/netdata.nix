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
          "allow connections from" = "netdata.local";
          "default port" = "19999";
        };
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    19999
  ];
}
