{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  symlinksPaths = {
    # cfg
    "${xlib.dirs.user-storage}/ssh/config" = ".ssh/config";
    "${xlib.dirs.user-storage}/beets" = ".config/beets";
    "${xlib.dirs.user-storage}/ludusavi" = ".config/ludusavi";
    "${xlib.dirs.user-storage}/solaar" = ".config/solaar";
    "${xlib.dirs.user-storage}/easyeffects" = ".config/easyeffects";
    "${xlib.dirs.user-storage}/KeePassXC" = ".config/keepassxc";
    "${xlib.dirs.user-storage}/v2rayN" = ".local/share/v2rayN";
    "/etc/nixos" = "Configuration";

    "${config.home.homeDirectory}/Games/PrismLaunchers/${config.home.username}" =
      ".local/share/PrismLauncher";
    "${xlib.dirs.vetymae-drive}/Users/oqyude/Music" = "Music";

    # smthng
    # "${xlib.dirs.soptur-drive}/AI/LM Studio" = ".lmstudio";
    "${xlib.dirs.therima-drive}" = "External";
  };
  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;
in
{
  imports = [
    ./minimal.nix
    ./modules/dconf.nix
    ./modules/packages.nix
    ./modules/plasma-manager.nix
    ./modules/noctalia.nix
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
  home.activation = {
    yaziSync = ''
      ${pkgs.rsync}/bin/rsync -Lrv "${config.home.homeDirectory}/.config/yazi/" "${xlib.dirs.user-storage}/yazi/"
    '';
  };
}
