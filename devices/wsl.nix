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
      device.type = "wsl";

      imports = with inputs; [
        nixos-wsl.nixosModules.default
        self.nixosModules.default

        self.nixosModules.software.beets
        self.nixosModules.server.open-webui
        self.homeConfigurations.default.nixosModule
      ];

      home-manager = {
        extraSpecialArgs = {
          inherit inputs;
          deviceType = config.device.type; # Переименовываем type в deviceType
        };
      };

      fileSystems = {
        # beets
        "/mnt/beets/music" = {
          device = "${inputs.zeroq.dirs.wsl-home}/Music";
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
        hostName = "${inputs.zeroq.devices.wsl.hostname}";
      };

      wsl = {
        enable = true;
        startMenuLaunchers = true;
        #useWindowsDriver = true;
        defaultUser = "${inputs.zeroq.devices.admin}";
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
