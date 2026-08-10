{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    "${config.home.homeDirectory}/External/Music" = "Music";
    "${xlib.dirs.wsl-home}" = "External";
    "${xlib.dirs.wsl-storage}" = "Storage";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  imports = [
    ./apps
    ./minimal.nix
  ];
  home.file = mkLinks;
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.wsl-storage}/yazi/"
    '';
  };
}
