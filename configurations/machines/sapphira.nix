{ inputs, ... }@flakeContext:
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

        home-manager.nixosModules.home-manager # home-manager module
        self.homeConfigurations.${inputs.zeroq.devices.server.username}.nixosModule # home-manager configuration module
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
        kernelPackages = pkgs.linuxPackages_xanmod_stable;
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

      nixpkgs = {
        config.allowUnfree = true;
        hostPlatform = lib.mkDefault "x86_64-linux";
      };

      users = {
        users = {
          "${inputs.zeroq.devices.server.username}" = {
            isNormalUser = true;
            description = "Server User";
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJpMaD143EZqhRlpAgNINLrH/qXkN3zXmKgFJlhbhGwg"
            ];
            initialPassword = "1234";
            extraGroups = [
              "users"
              "wheel"
              "networkmanager"
            ];
          };
        };
      };

      environment = {
        systemPackages = with pkgs; [
          acl
          btop # tty
          efibootmgr # Info
          fastfetch
          iptables
          lf # tty
          mc # tty
          parted # Disks
          pciutils # Info
          smartmontools # tty
          yazi
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
        "${inputs.zeroq.dirs.server-home}" = {
          device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
          fsType = "ext4";
          options = [
            "nofail"
            "x-systemd.device-timeout=0"
          ];
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
            #adminpassFile = "${inputs.zeroq.dirs.credentials-target}/nextcloud/admin-pass.txt";
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
              "valid users" = "${inputs.zeroq.devices.admin}";
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
              "valid users" = "${inputs.zeroq.devices.admin}";
              "guest ok" = "no";
              "writable" = "yes";
              #"create mask" = 0644;
              #"directory mask" = 0644;
              "force user" = "root";
              "force group" = "root";
            };
            "${inputs.zeroq.devices.server.username}" = {
              "path" = "${inputs.zeroq.dirs.server-home}";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${inputs.zeroq.devices.admin}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 700;
              "directory mask" = 700;
              "force user" = "${inputs.zeroq.devices.server.username}";
              "force group" = "users";
            };
          };
        };
        calibre-web = {
          enable = true;
          group = "users";
          user = "${inputs.zeroq.devices.server.username}";
          options = {
            calibreLibrary = "${inputs.zeroq.dirs.calibre-library}";
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
              path = "/etc/ssh/keys/${inputs.zeroq.devices.admin}";
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
          credentialsFile = "${inputs.zeroq.dirs.server-home}/server/transmission/settings.json";
          openRPCPort = true;
          package = pkgs.transmission_4;
          user = "${inputs.zeroq.devices.server.username}";
          group = "users";
          settings = {
            download-dir = "${inputs.zeroq.dirs.server-home}/Downloads";
            incomplete-dir = "${inputs.zeroq.dirs.server-home}/Downloads/Temp";
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
          configDir = "${inputs.zeroq.dirs.storage}/Syncthing/${inputs.zeroq.devices.server.hostname}";
          dataDir = "${inputs.zeroq.dirs.server-home}";
          group = "users";
          user = "${inputs.zeroq.devices.server.username}";
        };
        tailscale.enable = true;
      };

      security = {
        #     acme = {
        #       acceptTerms = true;
        #       defaults = {
        #        email = "${inputs.zeroq.devices.server.hostname}@example.com";
        #       };
        #       certs = {
        #        "${config.services.nextcloud.hostName}".group = "nextcloud";
        #       };
        #     };
      };

      networking = {
        hostName = "${inputs.zeroq.devices.server.hostname}";
        networkmanager.enable = true;
        firewall.enable = false;
        useDHCP = lib.mkDefault true;
      };

      system = {
        stateVersion = "24.05";
      };
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
