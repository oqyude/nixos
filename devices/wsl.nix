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

      imports = with inputs; [
        # Hardware
        nixos-wsl.nixosModules.default

        # Base
        self.homeConfigurations.default.nixosModule
        self.nixosModules.default

        # Custom
        self.nixosModules.software.beets
        self.nixosModules.server.open-webui
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      fileSystems = {
        # beets
        "/mnt/beets/music" = {
          device = "${config.xlib.dirs.wsl-home}/Music";
          options = [
            "bind"
            "uid=1000"
            "gid=1000"
            "fmask=0007"
            "dmask=0007"
            "nofail"
            "x-systemd.device-timeout=0"
          ];
        };
      };

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
  ];
  system = "x86_64-linux";
}
