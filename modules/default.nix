{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
let
  xlib.device.type = config.xlib.device.type;
  # isServer = config.xlib.device.type == "server";
in
{

  _module.args.deviceType = config.xlib.device.type or "none";

  imports = with inputs; [
    ./essentials
    ./users.nix
    ./options.nix
    #./overlays.nix
    ./temp.nix
    ./type.nix
    #(./. + "/${deviceType}") # specific modules

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];

  #server.enable = (config.xlib.device.type == "server");

  _module.args.inputs = inputs;
  services.immich.package = lib.mkIf (
    config.xlib.device.type == "server"
  ) inputs.self.packages.x86_64-linux.immich;
}
