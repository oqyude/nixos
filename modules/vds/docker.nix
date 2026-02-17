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

  # virtualisation = {
  #   docker.enable = true;
  # };

  environment.systemPackages = [
    pkgs.compose2nix
  ];
}
