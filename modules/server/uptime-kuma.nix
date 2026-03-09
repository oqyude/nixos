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
    enable = true;
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
    options = [
      "bind"
      "nofail"
    ];
  };
}
