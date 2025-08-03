{
  inputs,
  ...
}@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      device.type = "primary";

      imports = with inputs; [
        self.nixosModules.default

        nixos-hardware.nixosModules.chuwi-minibook-x
        home-manager.nixosModules.home-manager # home-manager module
        self.homeConfigurations.oqyude.nixosModule # home-manager configuration module
      ];
      hardware.intel-gpu-tools.enable = true;
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
