{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services.node-red = {
    enable = true;
  };
}
