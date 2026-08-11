{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ./minimal.nix
  ];
  home.file = xlib.helpers.mkSymlinks config {
    "${config.home.homeDirectory}/External/Music" = "Music";
  };
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv --no-A --no-X "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.storage}/yazi/"
    '';
  };
}
