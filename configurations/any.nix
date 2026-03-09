{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      xlib,
      ...
    }:
    {
      imports = [
        inputs.self.nixosModules.default
      ];

      system = {
        stateVersion = "26.05";
      };
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "minimal";
  };
}
