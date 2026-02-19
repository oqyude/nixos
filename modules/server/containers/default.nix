{
  lib,
  ...
}:
{
  imports = [
    ./remnawave.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    podman-tui
  ];
}
