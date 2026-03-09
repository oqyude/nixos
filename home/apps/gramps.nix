{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  grampsPath = "${xlib.dirs.wsl-storage}/gramps";
in
{
  xdg = {
    configFile = {
      "grampsConfig" = {
        source = config.lib.file.mkOutOfStoreSymlink grampsPath;
        target = "gramps";
      };
    };
    dataFile = {
      "grampsData" = {
        source = config.lib.file.mkOutOfStoreSymlink grampsPath;
        target = "gramps";
      };
    };
  };
  home.packages = [
    pkgs.gramps
  ];
}
