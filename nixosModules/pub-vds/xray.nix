{
  config,
  inputs,
  pkgs,
  ...
}:
{
  services.xray = {
    enable = true;
    settings = inputs.zeroq-credentials.public.services.xray;
  };

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ];
  };

  environment.systemPackages = [ pkgs.xray ];
}
