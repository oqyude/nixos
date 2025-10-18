{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  # Paths
  beetsPath = "${xlib.dirs.storage}/beets";
  sshPath = "${xlib.dirs.storage}/ssh";
  musicPath = "${config.home.homeDirectory}/External/Music";
in
{
  # imports = [
  #   ./minimal.nix
  # ];
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
      "ssh-config" = {
        source = config.lib.file.mkOutOfStoreSymlink "${sshPath}/config";
        target = ".ssh/config";
      };
      "ssh-known" = {
        source = config.lib.file.mkOutOfStoreSymlink "${sshPath}/known_hosts";
        target = ".ssh/known_hosts";
      };
      "Music" = {
        source = config.lib.file.mkOutOfStoreSymlink musicPath;
        target = "${config.home.homeDirectory}/Music";
      };
    };
  };
}
