{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  environment.systemPackages = [
    pkgs.aichat
  ];
}
