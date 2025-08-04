{ inputs, ... }@flakeContext:
{
  lib,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    ./users.nix
    (import ./options.nix { inherit lib inputs; }) # Options

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];
}
