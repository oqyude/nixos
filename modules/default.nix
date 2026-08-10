{ inputs, ... }@flakeContext:
let
  defaultModule =
    {
      config,
      deviceType,
      lib,
      xlib,
      ...
    }:
    {
      # NixOS-only modules. termux runs nix-on-droid (its own module system,
      # class = "nixOnDroid"): options like services.*, users.*, sops.*, disko.*
      # and nixpkgs.overlays (flake assertion) do not exist there.
      imports = with inputs; [
        ./essentials
        ./options.nix
        ./users.nix
        (./. + "/${deviceType}")

        home-manager.nixosModules.home-manager # home-manager module
        # nix-index-database.nixosModules.nix-index # nix-index module
        grub2-themes.nixosModules.default # grub2 themes module
        sops-nix.nixosModules.sops # sops module
        self.homeConfigurations.default.nixosModule # default homeConfigurations
        disko.nixosModules.disko # disko module
      ];
      nixpkgs.overlays = with inputs; [
        self.nixosOverlays.default
      ];
      networking.hostName = lib.mkDefault config.xlib.device.hostname;
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
      ...
    }:
    {
      imports = with inputs; [
        ./essentials
        ./users.nix
        ./options.nix

        disko.nixosModules.disko # disko module
        sops-nix.nixosModules.sops # sops module
      ];

      _module.args = {
        inputs = inputs;
        xlib = config.xlib;
      };
    };
  strictModule =
    {
      config,
      deviceType,
      lib,
      xlib,
      ...
    }:
    {
      imports = with inputs; [
        # ./essentials
        # ./users.nix
        ./options.nix
        (./. + "/${deviceType}")
        # sops-nix.nixosModules.sops
      ];

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
    strict = strictModule;
  };
}
