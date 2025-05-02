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

      imports = with inputs; [
        ./hardware-configuration/laptop.nix

        self.nixosModules.default
        self.nixosModules.software.wine

        home-manager.nixosModules.home-manager # home-manager module
        self.homeConfigurations.oqyude.nixosModule # home-manager configuration module
      ] ++ (builtins.attrValues inputs.self.nixosModules.desktop);

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
        #hardwareScan = true;
        kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
          timeout = 3;
        };
      };

      hardware = {
        logitech = {
          wireless = {
            enable = true;
            enableGraphical = true;
          };
        };
        graphics = {
          enable = true;
        };
        bluetooth.enable = true;
        nvidia = {
          open = true;
          dynamicBoost.enable = true;
          nvidiaSettings = true;
          powerManagement = {
            enable = false;
            finegrained = false; # maybe comment this out idk what it does
          };
          #package = config.boot.kernelPackages.nvidiaPackages.stable;
          nvidiaPersistenced = true;
          modesetting.enable = true;
          prime = {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
            sync.enable = false;
            amdgpuBusId = "PCI:6:0:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };
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

      environment = {
        systemPackages = with pkgs; [
          # Net
          curl
          ipset
          iptables
          nftables
          wget

          # Tools
          mc
          unzip
          rar
          ntfs3g
          gparted

          # Monitoring
          pciutils
          smartmontools
          usbutils
        ];
      };

      programs = {
        adb.enable = true;
        gamemode.enable = true;
        tuxclocker = {
          enable = false;
          enableAMD = true;
          useUnfree = true;
        };
        steam.enable = true;
        gamescope.enable = true;
      };

      services = {
        printing = {
          enable = true;
          cups-pdf.enable = true;
        };
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
                "default.clock.max-quantum" = 256;
                #"default.clock.force-quantum" = true;
              };
            };
          };
        };
        thermald.enable = true;
        earlyoom.enable = true;
        preload.enable = true;
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
