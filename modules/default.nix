{ inputs, ... }@flakeContext:
let
  # NixOS-only modules. termux runs nix-on-droid (its own module system,
  # class = "nixOnDroid"): options like services.*, users.*, sops.*, disko.*
  # and nixpkgs.overlays (flake assertion) do not exist there.
  moduleArgs = config: {
    inherit inputs;
    xlib = config.xlib;
  };
  defaultModule =
    {
      config,
      deviceType,
      lib,
      xlib,
      ...
    }:
    let
      isDesktop = builtins.elem deviceType [
        "primary"
        "secondary"
      ];
    in
    {
      imports =
        with inputs;
        [
          ./essentials
          ./options.nix
          ./users.nix

          home-manager.nixosModules.home-manager # home-manager module
          # nix-index-database.nixosModules.nix-index # nix-index module
          grub2-themes.nixosModules.default # grub2 themes module
          sops-nix.nixosModules.sops # sops module
          self.homeConfigurations.default.nixosModule # default homeConfigurations
          disko.nixosModules.disko # disko module
        ]
        ++ lib.optional isDesktop ./desktop # desktop class: primary/secondary
        # device-type module dir; "minimal" has no extra modules
        ++ lib.optional (!isDesktop && deviceType != "minimal") (./. + "/${deviceType}");
      nixpkgs.overlays = with inputs; [
        self.nixosOverlays.default
      ];
      networking.hostName = lib.mkDefault config.xlib.device.hostname;
      _module.args = moduleArgs config;
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

      _module.args = moduleArgs config;
    };
in
{
  nixosModules = {
    default = defaultModule;
    strict = strictModule;
  };
}
