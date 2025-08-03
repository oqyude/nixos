{
  config,
  ...
}:
{
  services = {
    tailscale.enable = config.device.type != "wsl"; # true, if not wsl
  };
}
