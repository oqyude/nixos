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
        nixosModule

        inputs.nixos-wsl.nixosModules.default

        inputs.self.homeConfigurations.default.nixosModule
        inputs.self.nixosModules.default
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
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "wsl";
  };
}
