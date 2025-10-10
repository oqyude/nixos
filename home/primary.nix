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
    ./modules/dconf.nix
    ./modules/packages.nix
    ./modules/plasma-manager.nix
    ./modules/external.nix
  ];
  xdg = {
    enable = true;
    autostart.enable = true;
    configFile = {
      "beets" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/beets";
        target = "beets";
      };
      "ludusavi" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/ludusavi/cfg";
        target = "ludusavi";
      };
      "solaar" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/solaar";
        target = "solaar";
      };
      "easyeffects" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/easyeffects";
        target = "easyeffects";
      };
      "keepassxc" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/KeePassXC";
        target = "keepassxc";
      };
    };
    dataFile = {
      "v2rayN" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.user-storage}/v2rayN";
        target = "v2rayN";
      };
    };
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
    file = {
      "External" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.therima-drive}";
        target = "External";
      };
      "LM Studio" = {
        source = config.lib.file.mkOutOfStoreSymlink "${xlib.dirs.soptur-drive}/AI/LM Studio";
        target = ".lmstudio";
      };
    };
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
