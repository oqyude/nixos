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
      device = {
        type = "primary";
        hostname = "atoridu";
      };

      imports = with inputs; [
        ./hardware/mini-pc.nix
        ./hardware/logitech.nix
        self.nixosModules.default
        self.homeConfigurations.default.nixosModule

        sops-nix.nixosModules.sops
        self.nixosModules.server.open-webui
        self.nixosModules.software.wine
        self.nixosModules.software.beets
        #self.nixosModules.extra.self.fingerprint
        self.nixosModules.desktop
        # self.homeConfigurations.main.nixosModule
        # self.homeConfigurations.root.nixosModule
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      sops = {
        defaultSopsFile = ./secrets/example.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
      };

      fileSystems = {
        "${config.xlib.dirs.therima-drive}" = {
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
        "${config.xlib.dirs.vetymae-drive}" = {
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
          device = "/home/${config.xlib.device.username}/Music"; # "${config.xlib.dirs.vetymae-drive}/Users/User/Music"
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
        hostName = "${config.xlib.device.hostname}";
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
          configDir = "${config.xlib.dirs.user-storage}/Syncthing/${config.system.name}";
          dataDir = "${config.xlib.dirs.user-home}";
          group = "users";
          user = "${config.xlib.device.username}";
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
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "primary";
  };
}
