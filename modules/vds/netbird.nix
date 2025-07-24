{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.netbird.server = {
    enable = true;
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      33073
      10000
      33080
    ];
    allowedUDPPorts = [ 3478 ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 65535;
      }
    ];
  };
}
