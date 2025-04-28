{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.zapret = {
    enable = true;
    httpMode = "full";
    params = [
      "--dpi-desync=fake,disorder2"
      "--dpi-desync-ttl=1"
      "--dpi-desync-autottl=2"
    ];

  };
  users.users.${inputs.zeroq.devices.admin} = {
    packages = with pkgs; [
      zapret
    ];
  };
}
