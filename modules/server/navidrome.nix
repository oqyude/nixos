{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  pointDir = "/var/lib/services/navidrome-point";
  libraryDir = "${xlib.dirs.server-home}/Music";
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
  systemd.mounts = [
    (xlib.helpers.mkSystemdBind {
      what = libraryDir;
      where = pointDir;
    })
  ];
}
