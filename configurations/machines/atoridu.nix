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
        self.nixosModules.global # global module
        self.nixosModules.special.${inputs.zeroq.devices.laptop.hostname} # special module

        home-manager.nixosModules.home-manager # home-manager module
        self.homeConfigurations.oqyude.nixosModule # home-manager configuration module
      ];

      boot = {
        #hardwareScan = true;
        kernelPackages = pkgs.linuxPackages_xanmod_stable;
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "usbhid"
            "usb_storage"
            "uas"
            "sd_mod"
          ];
        };
        kernelModules = [
          "kvm-amd"
          "vfio"
          "vfio-pci"
          "vfio_iommu_type1"
          "vfio_virqfd"
        ];
        kernelParams = [
          "amd_iommu=on"
          "iommu=pt"
          "kvm.ignore_msrs=1"
          #("vfio-pci.ids=" + builtins.concatStringsSep "," inputs.zeroq.platform.vfioIds)
        ];
        #extraModprobeConfig = "options vfio-pci ids=${builtins.concatStringsSep "," inputs.zeroq.platform.vfioIds}";
        extraModulePackages = [ config.boot.kernelPackages.amneziawg ];
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
        cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        graphics = {
          enable = true;
        };
        bluetooth.enable = true;
        #alsa.enable = false;
        nvidia = {
          open = true;
          dynamicBoost.enable = true;
          nvidiaSettings = true;
          powerManagement = {
            enable = false;
            finegrained = false; # maybe comment this out idk what it does
          };
          package = config.boot.kernelPackages.nvidiaPackages.stable;
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

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/5938c796-6ff5-49d9-a3a6-022b4c32beeb";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/61BF-3342";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
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

      swapDevices = [
        { device = "/dev/disk/by-uuid/d89bccd2-0672-4855-9d87-40e2688cdec4"; }
      ];

      networking = {
        hostName = "${inputs.zeroq.devices.laptop.hostname}";
        networkmanager.enable = true;
        firewall.enable = false;
        useDHCP = lib.mkDefault true;
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

      #qt = {
      #  enable = true;
      #  platformTheme = "kde6";
      #};

      environment = {
        plasma6.excludePackages = with pkgs.kdePackages; [
          plasma-browser-integration
          elisa
          kwrited
        ];
        gnome.excludePackages = with pkgs; [
          cheese # webcam tool
          epiphany # web browser
          #evince # document viewer
          geary # email reader
          gnome-characters
          gnome-music
          #gnome-photos
          gnome-tour
        ];
        systemPackages = with pkgs; [

          # Amneziawg. Temp
          linuxKernel.packages.linux_xanmod.amneziawg
          amneziawg-go
          amneziawg-tools

          # Net
          curl
          ipset
          iptables
          nftables
          wget

          # Wine
          #winetricks
          wineWowPackages.stagingFull
          wineWowPackages.yabridge
          wineWowPackages.fonts
          dxvk

          # Wine audio
          yabridge
          yabridgectl

          # Audio
          qjackctl

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

          # Windows virtualisation
          spice
          #spice-gtk
          #spice-protocol
          virt-manager
          virt-viewer
          virtiofsd
          win-spice
          virtio-win
          #looking-glass-client # pci-passthrough
        ];
        sessionVariables = {
          WINEPREFIX = "${inputs.zeroq.dirs.user-home}/${inputs.zeroq.dirs.state-folder}/wine"; # ${inputs.zeroq.dirs.state-folder}
          WINEARCH = "win64";
        };
      };

      programs = {
        xwayland.enable = true;
        dconf.enable = true;
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
        #udev = {
        #  packages = with pkgs; [ gnome-settings-daemon ];
        #};
        xserver = {
          enable = true;
          videoDrivers = [
            "amdgpu"
            "nvidia"
          ];
          xkb = {
            layout = "us,ru";
            variant = "";
            options = "grp:alt_shift_toggle";
          };
          #displayManager.gdm.enable = true;
          #displayManager.gdm.wayland = true;
          #desktopManager.gnome.enable = true;
        };
        displayManager = {
          #defaultSession = "plasma";
          sddm = {
            enable = true;
            wayland = {
              enable = true;
              compositor = "kwin";
            };
          };
        };
        desktopManager.plasma6.enable = true;
        printing = {
          enable = true;
          cups-pdf.enable = true;
        };
        libinput = {
          enable = true;
          mouse = {
            accelProfile = "flat";
          };
          touchpad = {
            accelProfile = "flat";
          };
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
          enable = true;
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
              };
            };
          };
        };
        thermald.enable = true;
        earlyoom.enable = true;
        preload.enable = true;
        spice-vdagentd.enable = true;
        resolved.enable = true;
      };

      security = {
        rtkit.enable = true;
      };

      virtualisation = {
        libvirtd = {
          enable = true;
          onBoot = "ignore";
          onShutdown = "shutdown";
          qemu = {
            swtpm.enable = true;
            ovmf.enable = true;
            ovmf.packages = [ pkgs.OVMFFull.fd ];
          };
        };
        spiceUSBRedirection.enable = true;
      };

      system.stateVersion = "24.11";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
