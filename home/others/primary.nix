{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    "/home/oqyude/Games/PrismLaunchers" = "${config.home.homeDirectory}/Games/PrismLaunchers";
    "${config.home.homeDirectory}/Games/PrismLaunchers/${config.home.username}" =
      ".local/share/PrismLauncher";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  imports = [
    ../minimal.nix
    ../modules/packages.nix
    ../modules/plasma-manager.nix
  ];
  xdg = {
    enable = true;
    autostart.enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.xdg.dataHome}/desktop";
      documents = null;
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Misc/Public";
      templates = null;
      videos = "${config.home.homeDirectory}/Pictures/Videos";
    };
  };
  home = {
    file = mkLinks;
    pointerCursor = {
      enable = true;
      x11.enable = true;
      gtk.enable = true;
      size = 24;
      name = "Qogir";
      package = pkgs.qogir-icon-theme;
    };
  };
}
