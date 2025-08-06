{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.netbird.server = {
    enable = false;
    enableNginx = true;
    domain = "netbird.zeroq.ru";
    dashboard = {
      enable = false;
      domain = "netbird.zeroq.ru";
      settings = {
        #AUTH_AUTHORITY = "nbp_ufe0v5mbb5H1lQWL8eJfuzJ5ItPmlM46Mik0";
      };
    };
    management = {
      enable = false;
      domain = "netbird.zeroq.ru";
    };
  };

  # networking.firewall = {
  #   allowedTCPPorts = [
  #     80
  #     443
  #     33073
  #     10000
  #     33080
  #   ];
  #   allowedUDPPorts = [ 3478 ];
  #   allowedUDPPortRanges = [
  #     {
  #       from = 49152;
  #       to = 65535;
  #     }
  #   ];
  # };
}
