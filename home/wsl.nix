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
    "${xlib.dirs.wsl-storage}/beets" = ".config/beets";
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
  xdg = {
    enable = true;
    autostart.enable = true;
    # configFile = {
    #   "beets" = {
    #     source = config.lib.file.mkOutOfStoreSymlink beetsPath;
    #     target = "beets";
    #   };
    # };
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
