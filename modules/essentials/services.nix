{
  config,
  ...
}:
{
  services = {
    tailscale.enable = !(config.wsl.enable or false); # true, if not wsl
  };
}
