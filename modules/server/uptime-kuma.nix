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
    (xlib.helpers.mkTmpfile "z" sourceDir "0755" "nobody" "nogroup")
  ];

  fileSystems = xlib.helpers.mkBindMount {
    what = sourceDir;
    where = targetDir;
  };
}
