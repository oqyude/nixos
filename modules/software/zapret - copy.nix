{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  services.zapret = {
    enable = true;
    httpMode = "full";
    udpSupport = true;
    udpPorts = [
      "50000:65535"
    ];
    params = [
      "--dpi-desync-any-protocol "
      "--dpi-desync=fake,disorder2"
      "--dpi-desync-ttl=1"
      "--dpi-desync-autottl=2"
    ];

  };
  #   users.users.${inputs.zeroq.devices.admin} = {
  #     packages = with pkgs; [
  #       zapret
  #     ];
  #   };
}
