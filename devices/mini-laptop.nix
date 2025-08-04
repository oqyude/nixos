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

      imports = with inputs; [
        self.homeConfigurations.default.nixosModule
        self.nixosModules.default

        nixos-hardware.nixosModules.chuwi-minibook-x
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      hardware.intel-gpu-tools.enable = true;
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
