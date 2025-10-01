{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services.node-red = {
    enable = true;
    port = 1880;
    openFirewall = true;
    userDir = "${xlib.dirs.services-mnt-folder}/node-red";
  };
  
  systemd.tmpfiles.rules = [
    "z ${xlib.dirs.services-mnt-folder}/node-red 0750 node-red node-red -"
  ];
}
