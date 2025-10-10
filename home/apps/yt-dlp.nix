{
  config,
  pkgs,
  xlib,
  ...
}:
let
  streamripPath = "${xlib.dirs.wsl-storage}/streamrip";
in
{
  # xdg = {
  #   configFile = {
  #     "streamrip" = {
  #       source = config.lib.file.mkOutOfStoreSymlink streamripPath;
  #       target = "streamrip";
  #     };
  #   };
  # };
  home.packages = [
    pkgs.yt-dlp-light
  ];
}
