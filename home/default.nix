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
        inputs.self.homeModules."${xlib.device.type}" # -> (./type + "/${xlib.device.type}.nix")
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
        inputs.self.homeModules."${xlib.device.type}"
      ];
      home = {
        username = "root";
        stateVersion = lib.mkDefault "25.05";
        homeDirectory = lib.mkDefault "/${config.home.username}";
        enableNixpkgsReleaseCheck = false;
      };
    };
  nixosModule =
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users."${config.xlib.device.username}" = homeModule;
        users.root = rootModule;
        sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
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
