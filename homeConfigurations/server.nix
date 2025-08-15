{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  # Paths
  beetsPath = "${xlib.dirs.storage}/beets/linux";
  sshPath = "${xlib.dirs.storage}/ssh/${xlib.device.hostname}";
  musicPath = "${config.home.homeDirectory}/External/Music";
in
{
  imports = [
    ./minimal.nix
  ];
  xdg = {
    configFile = {
      "beets" = {
        source = config.lib.file.mkOutOfStoreSymlink beetsPath;
        target = "beets";
      };
    };
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
  home = {
    file = {
      ".ssh" = {
        source = config.lib.file.mkOutOfStoreSymlink sshPath;
        target = ".ssh";
      };
      "Music" = {
        source = config.lib.file.mkOutOfStoreSymlink musicPath;
        target = "${config.home.homeDirectory}/Music";
      };
    };
  };
}
