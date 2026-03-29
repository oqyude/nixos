{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "d ${xlib.dirs.services-mnt-folder} 0755 root root -"
    "d ${xlib.dirs.services-mnt-folder}/containers 0755 root root -"
    "d ${xlib.dirs.services-mnt-folder}/containers/remnanode 0755 root root -"
  ];
}
