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
      imports =
        with inputs;
        [
          ./options.nix
          (./. + "/${deviceType}") # specific modules
        ]
        ++ lib.optionals (deviceType != "termux") [
          ./essentials
          ./users.nix

          home-manager.nixosModules.home-manager # home-manager module
          # nix-index-database.nixosModules.nix-index # nix-index module
          grub2-themes.nixosModules.default # grub2 themes module
          sops-nix.nixosModules.sops # sops module
          self.homeConfigurations.default.nixosModule # default homeConfigurations
          disko.nixosModules.disko # disko module
        ];
      # nix-on-droid asserts that nixpkgs.* stays unset in flake mode.
      nixpkgs.overlays = lib.mkIf (deviceType != "termux") (
        with inputs; [
          self.nixosOverlays.default
        ]
      );
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
in
{
  nixosModules = {
    default = defaultModule;
    public = publicModule;
  };
}
