{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  services.node-red = {
    enable = false;
    port = 1880;
    openFirewall = true;
    userDir = "${xlib.dirs.services-mnt-folder}/node-red";
    configFile = "${inputs.zeroq-credentials}/configs/node-red/settings.js";
  };

  systemd.tmpfiles.rules = [
    "z ${xlib.dirs.services-mnt-folder}/node-red 0750 node-red node-red -"
  ];
}
