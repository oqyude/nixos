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
    "${xlib.dirs.wsl-storage}/ssh/config" = ".ssh/config";
    "${xlib.dirs.wsl-storage}/ssh/known_hosts" = ".ssh/known_hosts";
    "${xlib.dirs.wsl-storage}/flow" = ".config/flow";
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
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.wsl-storage}/yazi/"
    '';
  };
}
