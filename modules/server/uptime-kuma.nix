{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  services.uptime-kuma = {
    enable = false;
    settings = {
      PORT = "4001";
      HOST = "0.0.0.0";
    };
  };

  systemd.tmpfiles.rules = [
    "z ${xlib.dirs.services-mnt-folder}/uptime-kuma 0755 nobody nogroup -"
  ];

  fileSystems."/var/lib/private/uptime-kuma" = {
    device = "${xlib.dirs.services-mnt-folder}/uptime-kuma";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };
}
