{
  config,
  pkgs,
  ...
}:
let
  grampsSource = "${xlib.dirs.wsl-storage}/gramps";
in
{
  xdg = {
    enable = true;
    autostart.enable = true;
    configFile = {
      # "gramps" = {
      #   source = config.lib.file.mkOutOfStoreSymlink grampsPath;
      #   target = "gramps";
      # };
    };
  };
  home.packages = [
    pkgs.gramps
  ];
}
