{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Paths
  beetsPath = "${inputs.zeroq.dirs.storage}/beets/linux";
  sshPath = "${inputs.zeroq.dirs.storage}/ssh/${inputs.zeroq.devices.server.hostname}";
  musicPath = "${config.home.homeDirectory}/External/Music";
in
{
  imports = [
    inputs.self.homeModules.minimal
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
