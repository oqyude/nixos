{ inputs, ... }@flakeContext:
let
  defaultModule =
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
        (./. + "/${deviceType}") # specific modules

        home-manager.nixosModules.home-manager # home-manager module
        nix-index-database.nixosModules.nix-index # nix-index module
        grub2-themes.nixosModules.default # grub2 themes module
        sops-nix.nixosModules.sops # sops module
        self.homeConfigurations.default.nixosModule # default homeConfigurations
        disko.nixosModules.disko # disko module
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      _module.args = {
        inputs = inputs;
        xlib = config.xlib;
      };
    };
  publicModule =
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
        (./. + "/${deviceType}") # specific modules

        home-manager.nixosModules.home-manager # home-manager module
        sops-nix.nixosModules.sops # sops module
        self.homeConfigurations.default.nixosModule # default homeConfigurations
        disko.nixosModules.disko # disko module
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      _module.args = {
        inputs = inputs;
        xlib = config.xlib;
      };
    };
in
{
  nixosModules = {
    default = defaultModule;
    public = publicModule;
  };
}
