{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    immich = {
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = true;
      mediaLocation = "${xlib.dirs.services-mnt-folder}/immich";
    };
  };

  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "z" config.services.immich.mediaLocation "0755" "immich" "immich")
  ];

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  environment = {
    systemPackages = with pkgs; [
      immich-cli
    ];
  };
}
