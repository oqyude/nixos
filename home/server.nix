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
    "${xlib.dirs.storage}/ssh" = ".ssh/config";
    "${xlib.dirs.storage}/ssh" = ".ssh/known_hosts";
    "${xlib.dirs.storage}/beets" = ".config/beets";

    # "hypr" = ".config/hypr";
    # "waybar" = ".config/waybar";
    # "rofi" = ".config/rofi";
    # "yazi" = ".config/yazi";

    # "alacritty" = ".config/alacritty";
    # "zellij" = ".config/zellij";

    # "zed" = ".config/zed";

    # "lazygit" = ".config/lazygit";

    # "fish/config.fish" = ".config/fish/config.fish";
    # "git/.gitconfig" = ".gitconfig";
    # "npm/.npmrc" = ".npmrc";
  };

  mkLinks = lib.mapAttrs' (sourcePath: targetPath: {
    name = targetPath;
    value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
  }) symlinksPaths;

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
    # configFile = {
    #   "beets" = {
    #     source = config.lib.file.mkOutOfStoreSymlink beetsPath;
    #     target = "beets";
    #   };
    # };
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
  home.file = mkLinks;
  # home = {
  #   file = {
  #     "ssh-config" = {
  #       source = config.lib.file.mkOutOfStoreSymlink "${sshPath}/config";
  #       target = ".ssh/config";
  #     };
  #     "ssh-known" = {
  #       source = config.lib.file.mkOutOfStoreSymlink "${sshPath}/known_hosts";
  #       target = ".ssh/known_hosts";
  #     };
  #     "Music" = {
  #       source = config.lib.file.mkOutOfStoreSymlink musicPath;
  #       target = "${config.home.homeDirectory}/Music";
  #     };
  #   };
  # };
}
