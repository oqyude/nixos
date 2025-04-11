{ inputs, ... }@flakeContext:
let
  homeModule = { config, lib, pkgs, ... }: {

    username = "oqyude";
    homeDirectory = "/home/oqyude";
    home = {
      packages = with pkgs; [
        brave
        vivaldi
      ];
    };

  };
  nixosModule = { ... }: {
    home-manager.users.oqyude = homeModule;
  };
in
(
  (
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        homeModule
      ];
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    }
  ) // { inherit nixosModule; }
)
