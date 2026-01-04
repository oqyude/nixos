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
    allowedTCPPorts = [
      8443
      9443
      13380
    ];
    allowedUDPPorts = [
      8443
      9443
      13380
    ];
  };

  environment.systemPackages = [ pkgs.xray ];

  # sops.secrets = {
  #   xray_uuid = {
  #     key = "uuid";
  #     mode = "0444";
  #     format = "yaml";
  #     sopsFile = ./secrets/xray.yaml;
  #     path = "/etc/xray/uuid";
  #   };
  #   xray_private-key = {
  #     path = "/etc/xray/private-key";
  #     key = "private-key";
  #     mode = "0444";
  #     format = "yaml";
  #     sopsFile = ./secrets/xray.yaml;
  #   };
  # };
}
