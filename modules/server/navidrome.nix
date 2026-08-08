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
      enable = true;
      openFirewall = true;
      # environmentFile = "";
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "${xlib.dirs.server-home}/Music";
      };
    };
  };
  # systemd.mounts = [
  #   {
  #     enable = true;
  #     options = "bind,x-systemd.automount,nofail";
  #     requires = [ "local-fs.target" ];
  #     type = "none";
  #     wantedBy = [ "multi-user.target" ];
  #     what = "${xlib.dirs.server-home}/Music";
  #     where = "/home/${xlib.device.username}/.config/beets";
  #   }
  # ];
}
