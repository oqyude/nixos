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
    ./temp.nix
    (./. + "/${deviceType}") # specific modules

    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];
  _module.args = {
    inputs = inputs;
    xlib = config.xlib;
  };
}
