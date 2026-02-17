{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./3x-ui.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    podman-tui
  ];
}
