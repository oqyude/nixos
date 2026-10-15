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
    ./modules/herdr.nix
    ./modules/herdr-runtime.nix
    ./modules/opencode.nix
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
