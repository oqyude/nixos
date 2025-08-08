{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      xlib.device = {
        type = "wsl";
        hostname = "wsl";
      };

      imports = [
        inputs.nixos-wsl.nixosModules.default
      ];

      #zramSwap.enable = true;
      services = {
        journald = {
          extraConfig = ''
            SystemMaxUse=512M
          '';
        };
        earlyoom.enable = true;
      };

      networking = {
        firewall.enable = false;
        hostName = config.xlib.device.hostname;
      };

      wsl = {
        enable = true;
        startMenuLaunchers = true;
        #useWindowsDriver = true;
        defaultUser = config.xlib.device.username;
      };

      system.stateVersion = "24.11";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule
    inputs.self.nixosModules.default
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "wsl";
  };
}
