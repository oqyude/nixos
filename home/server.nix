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
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  imports = [
    ./minimal.nix
  ];
  home.file = mkLinks;
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv --no-A --no-X "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.storage}/yazi/"
    '';
  };
}
