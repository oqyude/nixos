{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # shared container modules live in ../../containers
    # ../../containers/3x-ui.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    podman-tui
  ];
}
