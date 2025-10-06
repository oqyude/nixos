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
    };
  };

  # systemd.tmpfiles.rules = [
  #   "z ${xlib.dirs.services-mnt-folder}/node-red 0750 node-red node-red -"
  # ];
}
