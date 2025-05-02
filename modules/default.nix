{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      substituters = [
        "https://nixos-cache-proxy.cofob.dev"
      ];
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users = {
      "${inputs.zeroq.devices.admin}" = {
        isNormalUser = true;
        description = "Jor Oqyude";
        initialPassword = "1234";
        extraGroups = [
          "jackaudio"
          "audio"
          "disk"
          "gamemode"
          "libvirtd"
          "networkmanager"
          "pipewire"
          "qemu-libvirtd"
          "wheel"
        ];
      };
    };
  };

  time.timeZone = "Europe/Moscow";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      zsh-autoenv.enable = true;
      histSize = 10000;
      loginShellInit = "cd /etc/nixos && clear && fastfetch";
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
      };
      shellAliases = {
        # shell
        ff = "clear && fastfetch";
        l = "ls -l";

        # nixos
        #nir-switch = "sudo nixos-rebuild switch --flake ${inputs.zeroq.nixos}#${config.networking.hostName}";
        #nir-boot = "sudo nixos-rebuild boot --flake ${inputs.zeroq.nixos}#${config.networking.hostName}";
        #nir-test = "sudo nixos-rebuild test --flake ${inputs.zeroq.nixos}#${config.networking.hostName}";

        # ssh
        s-1 = "ssh sapphira-1";
        s-1t = "ssh sapphira-1t";

        # Somethings
        reboot-bios = "sudo systemctl reboot --firmware-setup";
      };
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
    nh = {
      enable = true;
      flake = "${inputs.zeroq.nixos}";
      clean = {
        enable = true;
        extraArgs = "--keep 3 --keep-since 2d";
        dates = "daily";
      };
    };
  };

  security = {
    sudo.wheelNeedsPassword = false;
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
  };

  environment = {
    systemPackages = with pkgs; [
      nixfmt-tree
    ];
  };
}
