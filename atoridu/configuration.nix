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
          "networkmanager"
          "wheel"
          "pipewire"
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
          logiops
          ludusavi
          obsidian
          reaper
          transmission_4-qt
          lutris
          gamehub
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # Net
    curl
    ipset
    iptables
    nftables

    # Other
    kdePackages.filelight
    whitesur-kde
    brave
    easyeffects
    eza
    fastfetch
    gparted
    lf
    localsend
    mc
    nixfmt-rfc-style
    pciutils
    smartmontools
    usbutils
    yazi
  ];

  programs = {
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
    tuxclocker = {
      enable = true;
      enableAMD = true;
      useUnfree = true;
    };
    steam.enable = true;
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
        wayland.compositor = "kwin";
      };
    };
    desktopManager.plasma6.enable = true;
    printing.enable = true;
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
    #resolved.enable = true;
    #cron.enable = true;
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

  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  system.stateVersion = "24.11";

}
