{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
# let
#   grampsPath = "${xlib.dirs.wsl-storage}/gramps";
# in
{
#   xdg = {
#     configFile = {
#       "grampsConfig" = {
#         source = config.lib.file.mkOutOfStoreSymlink grampsPath;
#         target = "gramps";
#       };
#     };
#     dataFile = {
#       "grampsData" = {
#         source = config.lib.file.mkOutOfStoreSymlink grampsPath;
#         target = "gramps";
#       };
#     };
#   };
  services.syncthing = {
    enable = true;
    tray.enable = true;
  };
  home.packages = [
  ];
}
