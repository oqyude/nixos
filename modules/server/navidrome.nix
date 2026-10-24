{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  libraryDir = "${xlib.dirs.server-home}/Music";
  pointDir = "/var/lib/services/navidrome-point";
in
{
  services = {
    navidrome = {
      enable = true;
      openFirewall = true;
      # environmentFile = "";
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "${pointDir}";
      };
    };
  };
  systemd = {
    mounts = [
      (xlib.helpers.mkSystemdBind {
        what = libraryDir;
        where = pointDir;
      })
    ];
    # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
    # directive and is ignored by systemd in `[Service]` (T4/R1.2).
    services.navidrome.unitConfig = xlib.helpers.mkStorageGuard xlib;
  };
}
