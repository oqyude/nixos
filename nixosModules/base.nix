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
    grub2-themes.nixosModules.default # grub2 themes module
    sops-nix.nixosModules.sops
    self.homeConfigurations.default.nixosModule
  ];
  _module.args = {
    inputs = inputs;
    xlib = config.xlib;
  };
}
