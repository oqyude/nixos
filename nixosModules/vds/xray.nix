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
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ]; # 41641
    #trustedInterfaces = [ "tailscale0" ];
  };

  environment.systemPackages = [ pkgs.xray ];
}
