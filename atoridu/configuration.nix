{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # My Lines
  my_vars = import ./my_vars.nix;
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{

  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  nix = {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/etc/nixos/${my_vars.this-host}/configuration.nix"
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
    hostName = "${my_vars.this-host}";
    networkmanager.enable = true;
    firewall.enable = false;
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
      "${my_vars.this-admin}" = {
        isNormalUser = true;
        description = "Jor Oqyude";
        initialPassword = "1234";
        extraGroups = [
          "gamemode"
          "libvirtd"
          "networkmanager"
          "pipewire"
          "wheel"
        ];
        packages = with pkgs; [
          # Workflow
          pdfarranger
          libreoffice-qt6

          vlc # Видео
          gramps # Генеалогическое древо
          stretchly
          nekoray
          discord
          mangohud
          _64gram
          keepassxc
          obsidian
          reaper
          transmission_4-qt
          lutris
          gamehub
          quickemu
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

      # Wine
      wineWowPackages.stagingFull
      winetricks
      dxvk

      # Audio
      wineasio
      yabridge
      yabridgectl

      # Other
      ludusavi
      kdePackages.filelight
      whitesur-kde
      brave
      easyeffects
      fastfetch
      gparted
      localsend
      mc
      nixfmt-rfc-style
      pciutils
      smartmontools
      usbutils
      btop

      # Windows virtualisation
      spice
      spice-gtk
      spice-protocol
      virt-manager
      virt-viewer
      win-spice
      win-virtio
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
      libraries = with pkgs; [
      ];
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
    pulseaudio.enable = lib.mkForce false;
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
      configDir = "${my_vars.dirs.storage}/Syncthing/${my_vars.this-host}";
      dataDir = "${my_vars.dirs.home}";
      group = "users";
      user = "${my_vars.this-admin}";
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
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };

  systemd = {
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

  # Oqyulink

  system.stateVersion = "24.11";

}
