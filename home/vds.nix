{
  config,
  pkgs,
  xlib,
  ...
}:
{
  imports = [
    ./minimal.nix
  ];
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
}
