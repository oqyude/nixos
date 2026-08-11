{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ./apps
    ./minimal.nix
  ];
  home.file = xlib.helpers.mkSymlinks config {
    "${config.home.homeDirectory}/External/Music" = "Music";
    "${xlib.dirs.wsl-home}" = "External";
    "${xlib.dirs.wsl-storage}" = "Storage";
  };
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.wsl-storage}/yazi/"
    '';
  };
}
