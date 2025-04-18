{
  inputs,
  zeroq,
  ...
}@flakeContext:
let
  current.host = "atoridu";
  nixosModule =
    {
      config,
      lib,
      pkgs,
      inputs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      nix = {
        #     nixPath = [
        #       "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        #       "nixos-config=/etc/nixos/${current.host}/configuration.nix"
        #       "/nix/var/nix/profiles/per-user/root/channels"
        #     ];
        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      nixpkgs.config = {
        #     hostPlatform = lib.mkDefault "x86_64-linux";
        allowUnfree = true;
        permittedInsecurePackages = [
          #"openssl-1.1.1w"
        ];
      };

      musnix.enable = true;

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
          "kvm-${zeroq.platform.cpu}"
          "vfio"
          "vfio-pci"
          "vfio_iommu_type1"
          "vfio_virqfd"
        ];
        kernelParams = [
          "${zeroq.platform.cpu}_iommu=on"
          "iommu=pt"
          "kvm.ignore_msrs=1"
          #("vfio-pci.ids=" + builtins.concatStringsSep "," zeroq.platform.vfioIds)
        ];
        #extraModprobeConfig = "options vfio-pci ids=${builtins.concatStringsSep "," zeroq.platform.vfioIds}";
        extraModulePackages = [ ];
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
        cpu."${zeroq.platform.cpu}".updateMicrocode =
          lib.mkDefault config.hardware.enableRedistributableFirmware;
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
            enable = true;
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
            "${zeroq.platform.cpu}gpuBusId" = "PCI:6:0:0";
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
        "${zeroq.dirs.therima-drive}" = {
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
        "${zeroq.dirs.vetymae-drive}" = {
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
        hostName = "${current.host}";
        networkmanager.enable = true;
        firewall.enable = false;
        useDHCP = lib.mkDefault true;
      };

      time.timeZone = "Europe/Moscow";
      i18n = {
        defaultLocale = "en_US.UTF-8";
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

      users = {
        defaultUserShell = pkgs.zsh;
        users = {
          "${zeroq.user-name}" = {
            isNormalUser = true;
            description = "Jor Oqyude";
            initialPassword = "1234";
            extraGroups = [
              "audio"
              "disk"
              "gamemode"
              "libvirtd"
              "networkmanager"
              "pipewire"
              "qemu-libvirtd"
              "wheel"
            ];
            packages = with pkgs; [
            ];
          };
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

          # Dev
          #gnumake

          # Audio
          yabridge
          yabridgectl
          wineasio
          qjackctl

          # Tools
          mc
          nixfmt-tree
          unzip
          rar
          ntfs3g
          gparted

          # Monitoring
          pciutils
          smartmontools
          usbutils

          # Windows virtualisation
          #           spice
          #           spice-gtk
          #           spice-protocol
          virt-manager
          virt-viewer
          #           win-spice
          #           virtio-win
          #looking-glass-client # pci-passthrough
        ];
        sessionVariables = {
          WINEPREFIX = "${zeroq.dirs.user-home}/${zeroq.dirs.state-folder}/wine"; # ${zeroq.dirs.state-folder}
          WINEARCH = "win64";
        };
      };

      programs = {
        xwayland.enable = true;
        dconf = {
          enable = true;
        };
        git = {
          enable = true;
          config = {
            user = {
              name = "oqyude";
              email = "oqyude@gmail.com";
            };
          };
        };
        lazygit.enable = true;
        nh.enable = true;
        zsh = {
          enable = true;
          enableCompletion = true;
          enableBashCompletion = true;
          syntaxHighlighting.enable = true;
          zsh-autoenv.enable = true;
          autosuggestions.enable = true;
          histSize = 10000;
          #loginShellInit = "cd /etc/nixos && clear && fastfetch";
          ohMyZsh = {
            enable = true;
            theme = "robbyrussell";
          };
          shellAliases = {
            # shell
            l = "ls -l";

            # nixos
            nir-switch = "sudo nixos-rebuild switch --flake ${zeroq.nixos}#${current.host}";
            nir-boot = "sudo nixos-rebuild boot --flake ${zeroq.nixos}#${current.host}";
            nir-test = "sudo nixos-rebuild test --flake ${zeroq.nixos}#${current.host}";

            # ssh
            s-1 = "ssh sapphira-1";
            s-1t = "ssh sapphira-1t";

            # Somethings
            reboot-bios = "sudo systemctl reboot --firmware-setup";
          };
        };
        gamemode.enable = true;
        tuxclocker = {
          enable = true;
          enableAMD = true;
          useUnfree = true;
        };
        steam = {
          enable = true;
          #gamescopeSession.enable = true;
        };
        gamescope = {
          enable = true;
        };
        kdeconnect = {
          enable = false;
          package = pkgs.gnomeExtensions.gsconnect;
        };
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
          configDir = "${zeroq.dirs.user-storage}/Syncthing/${current.host}";
          dataDir = "${zeroq.dirs.user-home}";
          group = "users";
          user = "${zeroq.user-name}";
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
            #             "99-default.conf" = {
            #               "default.clock.rate" = 96000;
            #               "default.clock.allowed-rates" = [
            #                 44100
            #                 48000
            #                 88200
            #                 96000
            #               ];
            #             };
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
        #jack.jackd.enable = false;
      };

      security = {
        sudo.wheelNeedsPassword = false;
        rtkit.enable = true;
        polkit = {
          enable = true;
          extraConfig = ''
            polkit.addRule(function(action, subject) {
                if ((action.id == "org.gnome.gparted" || // Для гнома
                    action.id == "org.freedesktop.policykit.exec") && // Для запуска Nekoray
                    subject.isInGroup("wheel")){ // Операции sudo
                    return polkit.Result.YES;
                }
            });
          '';
        };
      };

      virtualisation = {
        libvirtd = {
          enable = true;
          #       extraConfig = ''
          #         user="${zeroq.user-name}"
          #       '';
          onBoot = "ignore";
          onShutdown = "shutdown";
          qemu = {
            swtpm.enable = true;
            ovmf.enable = true;
            ovmf.packages = [ pkgs.OVMFFull.fd ];
            #         verbatimConfig = ''
            #           namespaces = []
            #           user = "+${builtins.toString config.users.users.${zeroq.user-name}.uid}"
            #         '';
          };
        };
        spiceUSBRedirection.enable = true;
      };

      systemd = {
        network.wait-online.enable = false;
        services = {
          #           base-start = {
          #             path = [ "/run/current-system/sw" ]; # Запуск в текущей системе
          #             script = ''
          #               treefmt /etc/nixos
          #             '';
          #             serviceConfig = {
          #               Type = "oneshot";
          #               RemainAfterExit = true;
          #             };
          #             wantedBy = [ "multi-user.target" ];
          #           };
        };
      };

      #       xdg = {
      #         portal.enable = true;
      #       };
      # Oqyulink

      system.stateVersion = "24.11";

    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule

    inputs.musnix.nixosModules.musnix
    inputs.home-manager.nixosModules.home-manager
    inputs.self.homeConfigurations.oqyude.nixosModule
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          hostname = current.host;
        };
      };
    }
  ];
  system = "x86_64-linux";
}
