{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  targetDir = "/var/lib/private/uptime-kuma";
  sourceDir = "${xlib.dirs.services-mnt-folder}/uptime-kuma";
in
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

  fileSystems."${targetDir}" = {
    device = "${xlib.dirs.services-mnt-folder}/uptime-kuma";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };
}
