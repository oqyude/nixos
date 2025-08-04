{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
let
  # Paths
  beetsPath = "${inputs.zeroq.dirs.wsl-storage}/beets/linux";
  #sshPath = "${inputs.zeroq.dirs.storage}/ssh/${inputs.zeroq.devices.server.hostname}";
  musicPath = "${config.home.homeDirectory}/External/Music";
  externalPath = "${inputs.zeroq.dirs.wsl-home}";
in
{

  xdg = {
    enable = true;
    autostart.enable = true;
    configFile = {
      "beets" = {
        source = config.lib.file.mkOutOfStoreSymlink beetsPath;
        target = "beets";
      };
    };
    # userDirs = {
    #   enable = false;
    #   createDirectories = false;
    #   desktop = null;
    #   documents = null;
    #   download = null;
    #   music = null;
    #   pictures = null;
    #   publicShare = null;
    #   templates = null;
    #   videos = null;
    # };
  };
  home = {
    #username = "${inputs.zeroq.devices.admin}";
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
    # pointerCursor = {
    #   enable = true;
    #   x11.enable = true;
    #   gtk.enable = true;
    #   size = 24;
    #   name = "Qogir";
    #   package = pkgs.qogir-icon-theme;
    # };
  };
}
