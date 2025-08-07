{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    tailscale.enable = config.xlib.device.type != "wsl"; # true, if not wsl
  };
}
