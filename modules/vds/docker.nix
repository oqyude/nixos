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

  environment.systemPackages = [
    pkgs.compose2nix
  ];
}
