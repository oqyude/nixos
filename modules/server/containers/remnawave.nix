{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
{


  # fileSystems."${config.services.immich.mediaLocation}" = {
  #   device = "${xlib.dirs.services-folder}/immich";
  #   options = [
  #     "bind"
  #     "nofail"
  #   ];
  # };

  # systemd.tmpfiles.rules = [
  #   "z ${config.services.immich.mediaLocation} 0755 immich immich -"
  # ];

  # environment = {
  #   systemPackages = with pkgs; [
  #     immich-cli
  #   ];
  # };
}
