{
  config,
  pkgs,
  xlib,
  ...
}:
{
  home.packages = [
    pkgs.streamrip
  ];
}
