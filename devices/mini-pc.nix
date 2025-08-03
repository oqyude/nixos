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
      imports = with inputs; [
        ./hardware/mini-pc.nix
        ./hardware/logitech.nix
        self.nixosModules.default

        self.nixosModules.server.ai
        self.nixosModules.software.wine
        self.nixosModules.software.ai
        self.nixosModules.software.beets
        #self.nixosModules.extra.self.fingerprint
        self.nixosModules.desktop
        self.homeConfigurations.main.nixosModule
        self.homeConfigurations.root.nixosModule
      ];

      sops = {
        defaultSopsFile = ./secrets/example.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
      };

      fileSystems = {
        "${inputs.zeroq.dirs.therima-drive}" = {
          device = "/dev/disk/by-uuid/C0A2DDEFA2DDEA44";
          fsType = "ntfs3";
          options = [
            "defaults"
            "uid=1000"
            "gid=1000"
            "fmask=0007"
            "dmask=0007"
            "nofail"
            #"x-systemd.device-timeout=0"
          ];
        };
        "${inputs.zeroq.dirs.vetymae-drive}" = {
          device = "/dev/disk/by-uuid/38D63C6ED63C2E8E";
          fsType = "ntfs3";
          options = [
            "defaults"
            "uid=1000"
            "gid=1000"
            "fmask=0007"
            "dmask=0007"
            "nofail"
            #"x-systemd.device-timeout=0"
          ];
        };
        "/mnt/beets/music" = {
          device = "/home/${inputs.zeroq.devices.admin}/Music"; # "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Music"
          options = [
            "bind"
            #"uid=1000"
            #"gid=1000"
            "fmask=0077"
            "dmask=0077"
            "nofail"
            #"x-systemd.device-timeout=0"
          ];
        };
      };

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;
        #kernelParams = [ "usbcore.autosuspend=-1" ];
        loader = {
          systemd-boot.enable = lib.mkDefault true;
          efi.canTouchEfiVariables = lib.mkDefault true;
        };
      };

      hardware = {
        bluetooth.enable = true;
        graphics.extraPackages = with pkgs; [
          amdvlk
        ];
      };

      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      networking = {
        hostName = "${inputs.zeroq.devices.laptop.hostname}";
        networkmanager.enable = true;
        firewall.enable = false;
      };

      i18n = {
        extraLocaleSettings = {
          LC_ADDRESS = "ru_RU.UTF-8";
          LC_IDENTIFICATION = "ru_RU.UTF-8";
          LC_MEASUREMENT = "ru_RU.UTF-8";
          LC_MONETARY = "ru_RU.UTF-8";
          LC_NAME = "ru_RU.UTF-8";
          LC_NUMERIC = "ru_RU.UTF-8";
          LC_PAPER = "ru_RU.UTF-8";
          LC_TELEPHONE = "ru_RU.UTF-8";
          LC_TIME = "ru_RU.UTF-8";
        };
      };

      services = {
        #logrotate.checkConfig = false;
        #power-profiles-daemon.enable = false;
        xserver = {
          videoDrivers = [
            "amdgpu"
          ];
        };
        syncthing = {
          enable = true;
          systemService = true;
          configDir = "${inputs.zeroq.dirs.user-storage}/Syncthing/${config.system.name}"; # ${inputs.zeroq.devices.laptop.hostname}
          dataDir = "${inputs.zeroq.dirs.user-home}";
          group = "users";
          user = "${inputs.zeroq.devices.admin}";
        };
        pipewire = {
          enable = lib.mkDefault true;
          systemWide = true;
          alsa.enable = false;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          extraConfig.pipewire = {
            "99-default.conf" = {
              "context.properties" = {
                "default.clock.rate" = 96000;
                "default.clock.allowed-rates" = [
                  44100
                  48000
                  96000
                ];
                "default.clock.quantum" = 1024;
                "default.clock.min-quantum" = 256;
                "default.clock.max-quantum" = 2048;
              };
            };
          };
        };
        thermald.enable = true;
        earlyoom.enable = true;
        preload.enable = true;
      };
      nixpkgs.config.pulseaudio = true;

      security = {
        rtkit.enable = true;
      };

      system.stateVersion = "25.11";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule
    inputs.sops-nix.nixosModules.sops
  ];
  system = "x86_64-linux";
}
