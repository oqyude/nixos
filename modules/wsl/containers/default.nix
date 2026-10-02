{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # shared container modules live in ../../containers
    ../../containers/kokoro-tts.nix
  ];

  environment.systemPackages = with pkgs; [
    compose2nix
    podman-tui
  ];
}
