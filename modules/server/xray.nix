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
    settings = import "${inputs.zeroq-credentials}/services/xray/config.nix";
    #settingsFile = "/etc/xray/config.json";
  };

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ];
  };

  environment.systemPackages = with pkgs; [ xray ];
}
