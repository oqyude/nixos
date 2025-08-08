{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      xlib,
      ...
    }:
    {
      xlib.device = {
        type = "wsl";
        hostname = "wsl";
      };

      imports = [
        inputs.nixos-wsl.nixosModules.default
        inputs.self.nixosModules.default
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
        hostName = xlib.device.hostname;
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
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "wsl";
  };
}
