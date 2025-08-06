{ inputs, ... }@flakeContext:
{
  config,
  lib,
  xlib,
  deviceType,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    ./users.nix
    ./options.nix
    #./overlays.nix
    ./temp.nix
    (./. + "/${deviceType}") # specific modules

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];

  #server.enable = (config.xlib.device.type == "server");

  _module.args.inputs = inputs;
  _module.args.xlib = config.xlib;
  services.immich.package = lib.mkIf (
    config.xlib.device.type == "server"
  ) inputs.self.packages.x86_64-linux.immich;
}
