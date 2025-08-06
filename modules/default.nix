{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    ./server
    ./users.nix
    ./options.nix
    ./temp.nix
    #(lib.mkIf (config.xlib.device.type == "server") (import ./server { inherit inputs config lib pkgs ; }))

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];
  _module.args.inputs = inputs;
}
