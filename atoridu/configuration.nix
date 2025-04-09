{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  stdenv,
  fetchurl,
  ...
}:

let
  current.host = "atoridu";
  zeroq = import ../vars.nix;
in
{

  imports = [
    #(import "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz"}/nixos")
    "${builtins.fetchTarball "https://github.com/musnix/musnix/archive/master.tar.gz"}"
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  musnix = {
    enable = true;
  };

  boot = {
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
    "${zeroq.dirs.sound-drive}" = {
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
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d89bccd2-0672-4855-9d87-40e2688cdec4"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nix = {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/etc/nixos/${current.host}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  };

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
      "${zeroq.admin}" = {
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
          # Workflow
          pdfarranger
          libreoffice-qt6

          vlc # Видео
          gramps # Genealogy
          stretchly
          nekoray
          discord
          _64gram
          keepassxc
          obsidian
          reaper
          transmission_4-qt
          lutris
          gamehub
        ];
      };
    };
  };

  environment = {
    sessionVariables = {
      WINEPREFIX = "$HOME/.wine64";
      WINEARCH = "win64";
    };
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
      dxvk

      # Audio
      wineasio

      #       (yabridge.overrideAttrs (oldAttrs: {
      #         version = "5.1.0";
      #         src = builtins.fetchTarball "https://github.com/robbert-vdh/yabridge/archive/refs/tags/5.1.0.tar.gz";
      #       }))
      #       (yabridgectl.overrideAttrs (oldAttrs: {
      #         version = "5.1.0";
      #         src = builtins.fetchTarball "https://github.com/robbert-vdh/yabridge/archive/refs/tags/5.1.0.tar.gz";
      #       }))

      # Other
      mc
      nixfmt-rfc-style
      nix-search-cli

      # DE
      brave
      easyeffects
      fastfetch
      gparted
      input-leap
      kdePackages.filelight
      localsend
      ludusavi
      whitesur-kde

      # Monitoring
      btop
      mangohud
      pciutils
      smartmontools
      usbutils

      # Windows virtualisation
      spice
      spice-gtk
      spice-protocol
      virt-manager
      virt-viewer
      win-spice
      win-virtio
      #looking-glass-client # pci-passthrough
    ];
  };

  #  Homemanager method
  #   dconf.settings = {
  #     "org/virt-manager/virt-manager/connections" = {
  #       autoconnect = ["qemu:///system"];
  #       uris = ["qemu:///system"];
  #     };
  #   };

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
    nix-ld = {
      enable = false;
      #       libraries = with pkgs; [
      #         zlib
      #         zstd
      #         stdenv.cc.cc
      #         curl
      #         openssl
      #         attr
      #         libssh
      #         bzip2
      #         libxml2
      #         acl
      #         libsodium
      #         util-linux
      #         xz
      #         systemd
      #       ];
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      zsh-autoenv.enable = true;
      loginShellInit = "cd /etc/nixos && clear && fastfetch";
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
      };
      shellAliases = {
        l = "ls -l";

        # ssh
        sr = "ssh sapphira-root";
        srt = "ssh sapphira-root-t";
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
      gamescopeSession.enable = true;
    };
    gamescope = {
      enable = true;
    };
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
        #"intel"
      ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    #pulseaudio.enable = lib.mkForce false;
    displayManager = {
      defaultSession = "plasma";
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
      user = "${zeroq.admin}";
    };
    tailscale.enable = true;
    pipewire = {
      enable = true;
      systemWide = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    thermald.enable = true;
    earlyoom.enable = true;
    preload.enable = true;
    spice-vdagentd.enable = true;
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
      #         user="${zeroq.admin}"
      #       '';
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
        #         verbatimConfig = ''
        #           namespaces = []
        #           user = "+${builtins.toString config.users.users.${zeroq.admin}.uid}"
        #         '';
      };
    };
    spiceUSBRedirection.enable = true;
  };

  systemd = {
    #     extraConfig = "DefaultLimitNOFILE=1048576"; # defaults to 1024 if unset
    network.wait-online.enable = false;
    services = {
      base-start = {
        path = [ "/run/current-system/sw" ]; # Запуск в текущей системе
        script = ''
          nixfmt /etc/nixos
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  };

  #   xdg = {
  #     portal = {
  #       enable = true;
  #       wlr.enable = true;
  #     };
  #   };

  # Oqyulink

  system.stateVersion = "24.11";

}
