{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    tailscale.enable = xlib.device.type != "wsl"; # true, if not wsl
  };
}
