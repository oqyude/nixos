{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # ./openhands.nix
    # ./remnawave.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    podman-tui
  ];
}
