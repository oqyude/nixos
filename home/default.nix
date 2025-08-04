{ inputs, ... }@flakeContext:
let
  homeModule =
     {
      config,
      lib,
      pkgs,
      deviceType
      ...
    }:
    {
      imports = [
        inputs.self.homeModules.${deviceType}
      ];
      home = {
        username = inputs.zeroq.devices.admin;
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
      deviceType
      ...
    }:
    {
      imports = [
        inputs.self.homeModules.${deviceType}
      ];
      home = {
        username = "root";
        stateVersion = lib.mkDefault "25.05";
        homeDirectory = lib.mkDefault "/${config.home.username}";
        enableNixpkgsReleaseCheck = false;
      };
    };
  nixosModule =
    { ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${inputs.zeroq.devices.admin} = homeModule;
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
