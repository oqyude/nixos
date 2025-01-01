{
  config,
  pkgs,
  libs,
  inputs,
  ...
}:

{

  imports = [
    ./hardware-configuration.nix # Аппаратная часть
    ./setup/mount.nix
    #inputs.home-manager.nixosModules.default
  ];

  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Локализация
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "ru_RU.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
    #extraLocaleSettings = {
    #  LC_ALL = "en_US.UTF-8";
    #  LC_LANGUAGE = "en_US.UTF-8";
    #  LC_ADDRESS = "en_US.UTF-8";
    #  LC_IDENTIFICATION = "en_US.UTF-8";
    #  LC_MEASUREMENT = "en_US.UTF-8";
    #  LC_MONETARY = "en_US.UTF-8";
    #  LC_NAME = "en_US.UTF-8";
    #  LC_NUMERIC = "en_US.UTF-8";
    #  LC_PAPER = "en_US.UTF-8";
    #  LC_TELEPHONE = "en_US.UTF-8";
    #  LC_TIME = "en_US.UTF-8";
    #};
    # console = {
    #   font = "Lat2-Terminus16";
    #   keyMap = "us";
    #   useXkbConfig = true; # use xkb.options in tty.
    # };
  };

  time.timeZone = "Europe/Moscow";

  # Конфигурация NixOS
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
  ];

  #  home-manager = {
  #    extraSpecialArgs = { inherit inputs; };
  #    users = {
  #      "yuyul" = import ./home.nix;
  #    };
  #  };

  # Пользователи
  users.users.yuyul = {
    isNormalUser = true;
    description = "YuYuL";
    initialPassword = "1234";
    extraGroups = [
      "networkmanager"
      "wheel"
      "yuyul"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      brave
      obsidian
      nekoray
      _64gram # Не обновлять, приведет к крашу
      transmission_4-gtk
      #reaper
      #prismlauncher
      #vesktop
      #freecad
      #onlyoffice-bin
    ];
  };

  programs = {
    #steam = {
    #  enable = true;
    #  protontricks.enable = true;
    #};
    #hyprland = {
    #  enable = true;
    #  xwayland.enable = true;
    #};
    #nm-applet = {
    #  enable = true;
    #  indicator = true;
    #};
    #waybar.enable = true;
    #weylus.enable = true;
    xwayland.enable = true;
    kdeconnect.enable = true;
    git.enable = true;
    lazygit.enable = true;
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      enableBashCompletion = true;
      ohMyZsh.enable = true;
    };
  };

  #xdg.portal = {
  #  enable = true;
  #  extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  #};

  services = {
    tailscale = {
      enable = true;
    };
    syncthing = {
      enable = true;
      systemService = true;
      dataDir = "/home/yuyul";
      group = "users";
      user = "yuyul";
    };
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };
    preload.enable = true;
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        settings = { };
        enable = true;
        wayland.enable = true;
        wayland.compositor = "kwin";
      };
    };
    desktopManager.plasma6.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [
        "intel"
        "nomodeset"
        "fbdev"
      ];
      xkb = {
        layout = "us,ru";
        options = "eurosign:e,caps:escape";
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    printing.enable = true; # Print services
    libinput.enable = true; # Touchpad and other
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

  environment = {
    sessionVariables = {
      #XDG_CONFIG_HOME = "$HOME/etc";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.var/lib";
      XDG_CACHE_HOME = "$HOME/.var/cache";
    };
    #variables = {
    #  GDK_SCALE = "1.5";
    #  GDK_DPI_SCALE = "1";
    #  QT_SCALE_FACTOR = "1";
    #  XFT_DPI = "192";
    #};
    systemPackages = with pkgs; [
      # WINE
      #
      #protonplus
      wineWowPackages.waylandFull
      wine64
      winetricks
      wineasio
      dosbox
      dosbox-x
      kdePackages.filelight
      sublime4
      sublime-merge
      acl # для прав
      fzf
      remmina
      kdePackages.kate # Text
      mc
      btop
      lf
      gparted # Disks
      eza
      nixfmt-rfc-style # Fronmatter
      fdupes
      neofetch
      #
      #
      # SOMETHING
      #wget # tty
      #gedit
      #
      #wlr-randr
      #iptables
      #efibootmgr
      #lshw-gui
      #glxinfo
      #pciutils
      #inteltool
      #hwinf
      #smartmontools
      # HYPRLAND
      #rofi-wayland
      #kitty
      #dunst
      #nwg-bar
      #anyrun
    ];
    plasma6.excludePackages = with pkgs.kdePackages; [ ];
  };

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  systemd.services = {
    base-start = {
      path = [ "/run/current-system/sw" ]; # Запуск в текущей системе
      description = "YuYuL";
      script = ''
        nixfmt /etc/nixos
        setfacl -R -m u:yuyul:rwx /etc/nixos
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

  # use the example session manager (no others are packaged yet so this is enabled by default,
  # no need to redefine it in your config for now)
  #media-session.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05";

}
