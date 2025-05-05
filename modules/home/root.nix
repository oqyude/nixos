{ inputs, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.self.homeModules.plasma-manager ];
      home = {
        username = "root";
        homeDirectory = "/root";
        stateVersion = "25.05";
      };
    };
  nixosModule =
    { ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.root = homeModule;
        sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
      };
    };
in
(
  (inputs.home-manager.lib.homeManagerConfiguration {
    modules = [
      homeModule
    ];
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  })
  // {
    inherit nixosModule;
  }
)
