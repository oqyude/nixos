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
      system.nixos.label = "stock";

      imports =
        with inputs;
        [
          ./hardware/laptop.nix

          self.nixosModules.software.wine
          #self.nixosModules.software.daw

          self.nixosModules.desktop
          nixos-hardware.nixosModules.asus-fa506ic
          home-manager.nixosModules.home-manager # home-manager module
          grub2-themes.nixosModules.default # grub2 themes module
          self.homeConfigurations.main.nixosModule # main user
          self.homeConfigurations.root.nixosModule # main user
        ]
        ++ (builtins.attrValues inputs.self.nixosModules.common)
        ++ (builtins.attrValues inputs.self.nixosModules.everywhere);

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
            "x-systemd.device-timeout=0"
          ];
        };
        "${inputs.zeroq.dirs.vetymae-drive}" = {
          device = "/dev/disk/by-uuid/6E04EA7F04EA49A3";
          fsType = "ntfs3";
          options = [
            "defaults"
            "uid=1000"
            "gid=1000"
            "fmask=0007"
            "dmask=0007"
            "nofail"
            "x-systemd.device-timeout=0"
          ];
        };
      };

      boot = {
        kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
        loader = {
          #systemd-boot.enable = true;
          grub = {
            enable = true;
            useOSProber           = true;
            #efiInstallAsRemovable = true;
            efiSupport            = true;
            device = "nodev";
            #fsIdentifier          = "label";
            extraEntries = ''
                menuentry "Reboot" {
                    reboot
                }
                menuentry "Poweroff" {
                    halt
                }
            '';
          };
          grub2-theme = {
            enable = true;
            theme = "whitesur";
            footer = true;
            customResolution = "1920x1080";  # Optional: Set a custom resolution
          };
          efi.canTouchEfiVariables = true;
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
        syncthing = {
          enable = true;
          systemService = true;
          configDir = "${inputs.zeroq.dirs.user-storage}/Syncthing/${inputs.zeroq.devices.laptop.hostname}";
          dataDir = "${inputs.zeroq.dirs.user-home}";
          group = "users";
          user = "${inputs.zeroq.devices.admin}";
        };
        tailscale.enable = true;
        pipewire = {
          enable = lib.mkDefault true;
          systemWide = true;
          alsa.enable = true;
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
                  88200
                  96000
                ];
                "default.clock.quantum" = 256;
                "default.clock.min-quantum" = 64;
                "default.clock.max-quantum" = 1024;
                #"default.clock.force-quantum" = true;
              };
            };
          };
        };
        thermald.enable = true;
        earlyoom.enable = true;
        preload.enable = false;
      };

      security = {
        rtkit.enable = true;
      };

      system.stateVersion = "25.05";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
