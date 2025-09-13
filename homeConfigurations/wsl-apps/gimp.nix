{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  home.packages = [
    pkgs.gimp
  ];
}
