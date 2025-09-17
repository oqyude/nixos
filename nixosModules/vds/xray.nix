{
  config,
  inputs,
  pkgs,
  ...
}:
{
  services.xray = {
    enable = true;
    settings = inputs.zeroq-credentials.services.xray;
  };

  networking.firewall = {
    allowedTCPPorts = [ 8443 ];
    allowedUDPPorts = [ 8443 ];
    #trustedInterfaces = [ "tailscale0" ];
  };

  environment.systemPackages = [ pkgs.xray ];
}
