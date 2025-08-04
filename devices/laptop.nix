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

      imports =
        with inputs;
        [
          ./hardware/laptop.nix
          ./hardware/logitech.nix
          self.nixosModules.default
          #nixos-hardware.nixosModules.asus-fa506ic

          self.nixosModules.software.wine
          self.nixosModules.software.beets
          self.nixosModules.desktop
          sops-nix.nixosModules.sops
        ]
        ++ builtins.attrValues inputs.self.nixosModules.extra.self;

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
          device = "/dev/disk/by-uuid/6E04EA7F04EA49A3";
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
          device = "/home/${config.xlib.devices.admin}/Music"; # "${config.xlib.dirs.vetymae-drive}/Users/User/Music"
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
        kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
        kernelParams = [ "usbcore.autosuspend=-1" ];
        loader = {
          systemd-boot.enable = lib.mkDefault true;
          efi.canTouchEfiVariables = lib.mkDefault true;
        };
      };

      hardware = {
        bluetooth.enable = true;
        #         nvidia = {
        #           open = true;
        #           dynamicBoost.enable = true;
        #           nvidiaSettings = true;
        #           powerManagement = {
        #             enable = false;
        #             finegrained = false; # maybe comment this out idk what it does
        #           };
        #           #package = config.boot.kernelPackages.nvidiaPackages.stable;
        #           nvidiaPersistenced = true;
        #           modesetting.enable = true;
        #           prime = {
        #             offload = {
        #               enable = true;
        #               enableOffloadCmd = true;
        #             };
        #             sync.enable = false;
        #             amdgpuBusId = "PCI:6:0:0";
        #             nvidiaBusId = "PCI:1:0:0";
        #           };
        #         };
      };

      # networking.firewall.allowedTCPPorts = [ ... ];
      # networking.firewall.allowedUDPPorts = [ ... ];
      networking = {
        hostName = "${config.xlib.devices.laptop.hostname}";
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
        xserver = {
          videoDrivers = [
            "amdgpu"
            "nvidia"
          ];
        };
        syncthing = {
          enable = true;
          systemService = true;
          configDir = "${config.xlib.dirs.user-storage}/Syncthing/${config.system.name}"; # ${config.xlib.devices.laptop.hostname}
          dataDir = "${config.xlib.dirs.user-home}";
          group = "users";
          user = "${config.xlib.devices.admin}";
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

      #services.power-profiles-daemon.enable = false;

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
}
