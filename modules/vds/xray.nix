{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.xray = {
    enable = true;
    settings = inputs.zeroq-credentials.services.xray;
  };

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ];
  };

  environment.systemPackages = with pkgs; [ xray ];
}
