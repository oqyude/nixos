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
    "${xlib.dirs.storage}/beets" = ".config/beets";
    "${xlib.dirs.storage}/ssh/config" = ".ssh/config";
    "${xlib.dirs.storage}/ssh/known_hosts" = ".ssh/known_hosts";
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
  xdg = {
    enable = true;
    autostart.enable = true;
    userDirs = {
      enable = true;
      createDirectories = false;
      desktop = null;
      documents = null;
      download = null;
      music = null;
      pictures = null;
      publicShare = null;
      templates = null;
      videos = null;
    };
  };
}
