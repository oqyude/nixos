{
  config,
  pkgs,
  xlib,
  ...
}:
let
  # Paths
  beetsPath = "${xlib.dirs.wsl-storage}/beets/linux";
  externalPath = "${xlib.dirs.wsl-home}";
  musicPath = "${config.home.homeDirectory}/External/Music";
in
{
  imports = [
    ./wsl-apps
    ./minimal.nix
  ];
  xdg = {
    enable = true;
    autostart.enable = true;
    configFile = {
      "beets" = {
        source = config.lib.file.mkOutOfStoreSymlink beetsPath;
        target = "beets";
      };
    };
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
  home = {
    file = {
      "External" = {
        source = config.lib.file.mkOutOfStoreSymlink externalPath;
        target = "External";
      };
      "Music" = {
        source = config.lib.file.mkOutOfStoreSymlink musicPath;
        target = "${config.home.homeDirectory}/Music";
      };
    };
  };
}
