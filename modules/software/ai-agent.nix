{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  environment.systemPackages = [
    pkgs.open-interpreter
  ];
}
