{ inputs, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      xlib,
      ...
    }:
    {

      imports = [
        (./. + "/${xlib.device.type}.nix")
      ];
      home = {
        username = xlib.device.username;
        stateVersion = lib.mkDefault "25.05";
        homeDirectory = lib.mkDefault "/home/${config.home.username}";
        enableNixpkgsReleaseCheck = false;
      };
    };
  rootModule =
    {
      config,
      lib,
      pkgs,
      xlib,
      ...
    }:
    {
      imports = [
        (./. + "/${xlib.device.type}.nix")
      ];
      home = {
        username = "root";
        stateVersion = lib.mkDefault "25.05";
        homeDirectory = lib.mkDefault "/${config.home.username}";
        enableNixpkgsReleaseCheck = false;
      };
    };
  nixosModule =
    { xlib, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users."${xlib.device.username}" = homeModule;
        users.root = rootModule;
        sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
        extraSpecialArgs = { inherit inputs; };
      };
    };
in
(
  (inputs.home-manager.lib.homeManagerConfiguration {
    modules = [
      homeModule
      rootModule
    ];
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  })
  // {
    inherit nixosModule;
  }
)
