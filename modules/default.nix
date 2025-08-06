{ inputs, ... }@flakeContext:
{
  lib,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    ./users.nix
    ./options.nix
    ./temp.nix
    (lib.mkIf (config.xlib.device.type == "server") (import ./server { inherit inputs; }))

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];
}
