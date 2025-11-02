{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  grampsPath = "${xlib.dirs.wsl-storage}/gramps";
  # last-stable = import inputs.nixpkgs-last-unstable { system = "x86_64-linux"; };
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
