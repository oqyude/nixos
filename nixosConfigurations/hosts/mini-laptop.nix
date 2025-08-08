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
      xlib.device = {
        type = "primary";
        hostname = "lamet";
      };

      imports = [
        inputs.nixos-hardware.nixosModules.chuwi-minibook-x
      ];

      hardware.intel-gpu-tools.enable = true;
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
    self.nixosModules.default
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "primary";
  };
}
