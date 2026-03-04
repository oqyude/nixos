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
          "hostname" = "netdata.local";
        };
      };
    };
  };
  
  networking.firewall.allowedTCPPorts = [
    19999
  ];
}
