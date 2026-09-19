{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    glances = {
      enable = true;
      openFirewall = true;
      port = 61208;
      extraArgs = [
        "--bind 100.64.0.0"
      ];
    };
  };
}
