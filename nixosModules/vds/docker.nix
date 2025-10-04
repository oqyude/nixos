{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # ./3x-ui.nix
  ];

  # virtualisation = {
  #   docker.enable = true;
  # };

  environment.systemPackages = [
    # inputs.compose2nix.packages.x86_64-linux.default
  ];
}
