{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    navidrome = {
      enable = false;
      openFirewall = true;
      # environmentFile = "";
      settings = {
        Address = "0.0.0.0";
        Port = "4533";
        MusicFolder = "/mnt/beets/music";
      };
    };
  };
}
