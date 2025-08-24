{
  config,
  pkgs,
  xlib,
  ...
}:
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
    pkgs.tmsu
  ];
}
