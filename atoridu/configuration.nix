# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  my_vars = import ./my_vars.nix;
in
{

  imports = [
    ./hardware-configuration.nix
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
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  networking.hostName = "${my_vars.this-host}";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  services = {
    xserver = {
      enable = true;
      videoDrivers = [
        "amdgpu"
        "nvidia"
      ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    pulseaudio.enable = lib.mkForce false;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
    #     displayManager.defaultSession = "plasma";
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
      #jack.enable = false;
    };
    thermald.enable = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
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
          solaar
          logiops
          ludusavi
          keepassxc
          obsidian
          _64gram
          reaper
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bluez
    usbutils
    easyeffects
    btop
    lf
    mc
    fastfetch
    brave
    localsend
    nixfmt-rfc-style
    yazi
    smartmontools
    iptables
    eza
    gparted
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

  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  networking.firewall.enable = false;

  system.stateVersion = "24.11";

}
