{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./essentials
    #./services

    # Flake modules
    inputs.home-manager.nixosModules.home-manager # home-manager module
    inputs.nix-index-database.nixosModules.nix-index
  ];
}
