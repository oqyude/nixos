{ inputs, ... }@flakeContext:
let
  # NixOS-only modules. termux runs nix-on-droid (its own module system,
  # class = "nixOnDroid"): options like services.*, users.*, sops.*, disko.*
  # and nixpkgs.overlays (flake assertion) do not exist there.
  #
  # `xlib` arrives as a module argument (see lib/mkSystem.nix) and is plain
  # data, not a module option, so nothing here has to declare or set it.
  defaultModule =
    {
      lib,
      xlib,
      ...
    }:
    {
      imports =
        with inputs;
        [
          ./essentials
          ./users.nix

          home-manager.nixosModules.home-manager # home-manager module
          # nix-index-database.nixosModules.nix-index # nix-index module
          grub2-themes.nixosModules.default # grub2 themes module
          sops-nix.nixosModules.sops # sops module
          justray.nixosModules.default
          self.homeConfigurations.default.nixosModule # default homeConfigurations
          disko.nixosModules.disko # disko module
        ]
        # desktop class: primary/secondary
        ++ lib.optional xlib.isDesktop ./desktop
        # device-type module dir; "minimal" has no extra modules
        ++ lib.optional (!xlib.isDesktop && xlib.device.type != "minimal") (./. + "/${xlib.device.type}");
      nixpkgs.overlays = with inputs; [
        self.nixosOverlays.default
      ];
      networking.hostName = lib.mkDefault xlib.device.hostname;
    };
  strictModule =
    {
      xlib,
      ...
    }:
    {
      imports = [
        # ./essentials
        # ./users.nix
        (./. + "/${xlib.device.type}")
        # sops-nix.nixosModules.sops
      ];
    };
in
{
  nixosModules = {
    default = defaultModule;
    strict = strictModule;
  };
}
