{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  current.host = "sapphira";
  zeroq = import ../vars.nix;
in
{

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    #nixPath = [
    #  "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    #  "nixos-config=/etc/nixos/${current.host}/configuration.nix"
    #  "/nix/var/nix/profiles/per-user/root/channels"
    #];
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    #"${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
    #./disko.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
    };
    kernel = {
      sysctl = {
        "fs.inotify.max_user_watches" = "204800";
      };
    };

    kernelModules = [
      "kvm-intel"
      "coretemp"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    hardwareScan = true;
    blacklistedKernelModules = [
      ""
    ];
    extraModulePackages = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    bluetooth.enable = false;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  #swapDevices =
  #  [ { device = "/dev/disk/by-partlabel/disk-main-swap"; }
  #  ];

  time.timeZone = "Europe/Moscow";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "ru_RU.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhxTIqodDYFpXbl12Qe/Sc1PIhsjBrOja+5z3FB/VgF root@${current.host}"
        ];
      };
      "${zeroq.admin}" = {
        isNormalUser = true;
        description = "Admin";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpMaD143EZqhRlpAgNINLrH/qXkN3zXmKgFJlhbhGwg ${zeroq.admin}@${current.host}"
        ];
        initialPassword = "1234";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        packages = with pkgs; [ ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      acl
      btop # tty
      efibootmgr # Info
      eza
      fastfetch
      iptables
      lf # tty
      mc # tty
      nixfmt-rfc-style # Fronmatter
      parted # Disks
      pciutils # Info
      sing-box
      smartmontools # tty
      yazi
      nix-search-cli
    ];
  };

  fileSystems = {
    # System
    "/" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    # External drive
    "${zeroq.dirs.server-home}" = {
      device = "/dev/disk/by-partlabel/Server";
      fsType = "ext4";
      options = [
        "nofail"
        "x-systemd.device-timeout=0"
      ];
    };

    # Mounts
    "${zeroq.dirs.credentials-target}" = {
      device = "${zeroq.dirs.credentials-source-server}";
      fsType = "none";
      options = [ "bind" ];
    };
  };

  services = {
    nextcloud = {
      enable = false;
      package = pkgs.nextcloud30;
      hostName = "localhost:10000";
      database.createLocally = true;
      config = {
        dbtype = "mysql";
        dbuser = "nextcloud";
        #dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "root";
        adminpassFile = "${zeroq.dirs.credentials-target}/nextcloud/admin-pass.txt";
      };
      settings = {
        appstoreEnable = false;
        log_type = "file";
        trusted_domains = [
          "100.64.0.0"
          "192.168.1.18"
          "localhost"
        ];
      };
      extraAppsEnable = true;
      extraApps = {
        inherit (pkgs.nextcloud30Packages.apps)
          bookmarks
          calendar
          contacts
          cookbook
          cospend
          deck
          end_to_end_encryption
          forms
          gpoddersync
          groupfolders
          impersonate
          integration_paperless
          mail
          maps
          memories
          music
          notes
          notify_push
          onlyoffice
          polls
          previewgenerator
          richdocuments
          spreed
          tasks
          user_oidc
          user_saml
          whiteboard
          ;
      };
    };
    earlyoom.enable = true;
    preload.enable = true;
    auto-cpufreq.enable = true;
    throttled.enable = true;
    nginx = {
      enable = false;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "localhost:10000" = {
          forceSSL = false;
          enableACME = false;
          listen = [
            {
              addr = "100.64.0.0";
              port = 10000;
            }
            {
              addr = "192.168.1.18";
              port = 10000;
            }
          ];
        };
      };
    };
    postgresql = {
      enable = false;
      #  ensureDatabases = [ "nextcloud" ];
      #  ensureUsers = [
      #    {
      #      name = "nextcloud"; # Здесь не хватает строчек\\
      #    }
      #  ];
    };
    journald = {
      extraConfig = ''
        SystemMaxUse=128M
      '';
    };
    samba = {
      enable = true;
      settings = {
        global = {
          "invalid users" = [ ];
          "passwd program" = "/run/wrappers/bin/passwd %u";
          security = "user";
        };
        nixos = {
          "path" = "/etc/nixos";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "root oqyude";
          "guest ok" = "no";
          "writable" = "yes";
          "create mask" = 644;
          "directory mask" = 644;
          "force user" = "root";
          "force group" = "root";
        };
        root = {
          "path" = "/";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "root oqyude";
          "guest ok" = "no";
          "writable" = "yes";
          #"create mask" = 0644;
          #"directory mask" = 0644;
          "force user" = "root";
          "force group" = "root";
        };
        server = {
          "path" = "/mnt/server";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "root oqyude";
          "guest ok" = "no";
          "writable" = "yes";
          "create mask" = 775;
          "directory mask" = 775;
          "force user" = "oqyude";
          "force group" = "users";
        };
      };
    };
    calibre-web = {
      enable = true;
      group = "users";
      user = "${zeroq.admin}";
      #dataDir = "${zeroq.dirs.server-home}";
      options = {
        calibreLibrary = "${zeroq.dirs.calibre-library}";
        enableBookUploading = true;
        enableKepubify = false;
      };
      listen.ip = "0.0.0.0";
      listen.port = 8083;
      openFirewall = true;
    };
    openssh = {
      enable = true;
      allowSFTP = true;
      hostKeys = [
        {
          path = "/etc/ssh/keys/root";
          type = "ed25519";
        }
        {
          path = "/etc/ssh/keys/${zeroq.admin}";
          type = "ed25519";
        }
      ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "yes";
        UsePAM = true;
      };
    };
    transmission = {
      enable = true;
      credentialsFile = "${zeroq.dirs.credentials-target}/transmission/settings.json";
      openRPCPort = true;
      package = pkgs.transmission_4;
      settings = {
        download-dir = "${zeroq.dirs.server-home}/Downloads";
        incomplete-dir = "${zeroq.dirs.server-home}/Downloads/Temp";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-port = 9091;
        rpc-whitelist-enabled = false;
        umask = 0;
      };
    };
    syncthing = {
      enable = true;
      systemService = true;
      guiAddress = "0.0.0.0:8384";
      configDir = "${zeroq.dirs.storage}/Syncthing/${current.host}";
      dataDir = "${zeroq.dirs.server-home}";
      group = "users";
      user = "${zeroq.admin}";
    };
    tailscale.enable = true;
  };

  security = {
    #     acme = {
    #       acceptTerms = true;
    #       defaults = {
    #        email = "${current.host}@example.com";
    #       };
    #       certs = {
    #        "${config.services.nextcloud.hostName}".group = "nextcloud";
    #       };
    #     };
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

  programs = {
    nh.enable = true;
    git.enable = true;
    lazygit.enable = true;
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
        # shell
        l = "ls -l";

        # nixos
        nir-switch = "sudo nixos-rebuild switch --flake /etc/nixos#${current.host}";
        nir-boot = "sudo nixos-rebuild boot --flake /etc/nixos#${current.host}";
        nir-test = "sudo nixos-rebuild test --flake /etc/nixos#${current.host}";
      };
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

  networking = {
    hostName = "${current.host}";
    networkmanager.enable = true;
    firewall.enable = false;
    useDHCP = lib.mkDefault true;
  };

  system = {
    stateVersion = "24.05";
  };
}
