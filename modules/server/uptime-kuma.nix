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

  systemd = {
    tmpfiles.rules = [
      (xlib.helpers.mkTmpfile "z" sourceDir "0755" "nobody" "nogroup")
    ];
    # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
    # directive and is ignored by systemd in `[Service]` (T4/R1.2).
    services."uptime-kuma".unitConfig = xlib.helpers.mkStorageGuard xlib;
  };

  fileSystems = xlib.helpers.mkBindMount {
    what = sourceDir;
    where = targetDir;
  };
}
