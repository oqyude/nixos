{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
# let
#   isServer = config.xlib.device.type == "server";
# in
{
  imports = with inputs; [
    ./essentials
    ./users.nix
    ./options.nix
    #./overlays.nix
    ./temp.nix
    ../nixosModules/server

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];

  server.enable = (config.xlib.device.type == "server");

  _module.args.inputs = inputs;
  services.immich.package = lib.mkIf (
    config.xlib.device.type == "server"
  ) inputs.self.packages.x86_64-linux.immich;
}
