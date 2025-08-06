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
      xlib.device = {
        type = "server";
        hostname = "sapphira";
      };

      imports = [
        ./hardware/server.nix

        self.nixosModules.server.immich
        self.nixosModules.server.nextcloud
        self.nixosModules.server.nginx
        self.nixosModules.software.beets
      ];

      home-manager = {
        extraSpecialArgs = {
          xlib = config.xlib;
        };
      };

      boot = {
        kernelPackages = pkgs.linuxPackages_xanmod_stable;
        hardwareScan = true;
        loader = {
          systemd-boot.enable = lib.mkDefault true;
          efi.canTouchEfiVariables = lib.mkDefault true;
        };
      };

      hardware = {
        bluetooth.enable = true;
      };

      # swapDevices = [
      #   { device = "/dev/disk/by-partlabel/disk-main-swap"; }
      # ];

      users = {
        users = {
          "${config.xlib.device.username}" = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P root@sapphira"
            ];
          };
        };
      };

      fileSystems = {
        # External drive
        "${config.xlib.dirs.server-home}" = {
          device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
          fsType = "ext4";
          options = [
            #"nofail"
            "x-systemd.device-timeout=0"
          ];
        };
        # Archive drive
        "/mnt/archive" = {
          device = "/dev/disk/by-label/archive";
          fsType = "exfat";
          options = [
            "nofail"
            "x-systemd.device-timeout=0"
            "uid=1000"
            "gid=1000"
          ];
        };
        # beets
        "/mnt/beets/music" = {
          device = "${config.xlib.dirs.server-home}/Music";
          options = [
            "bind"
            "uid=1000"
            "gid=1000"
            "fmask=0007"
            "dmask=0007"
            "nofail"
            "x-systemd.device-timeout=0"
          ];
        };
      };

      services = {
        power-profiles-daemon.enable = lib.mkForce false;
        earlyoom.enable = true;
        preload.enable = true;
        auto-cpufreq.enable = false;
        throttled.enable = true;
        journald = {
          extraConfig = ''
            SystemMaxUse=512M
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
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 755;
              "directory mask" = 755;
              "force user" = "${config.xlib.device.username}";
              "force group" = "users";
            };
            root = {
              "path" = "/";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              #"create mask" = 0644;
              #"directory mask" = 0644;
              "force user" = "root";
              "force group" = "root";
            };
            "${config.xlib.device.username}" = {
              "path" = "${config.xlib.dirs.server-home}";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 700;
              "directory mask" = 700;
              "force user" = "${config.xlib.device.username}";
              "force group" = "users";
            };
          };
        };
        calibre-web = {
          enable = true;
          group = "users";
          user = "${config.xlib.device.username}";
          options = {
            calibreLibrary = "${config.xlib.dirs.calibre-library}";
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
              path = "/etc/ssh/id_ed25519";
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
          enable = false;
          credentialsFile = "${config.xlib.dirs.server-home}/server/transmission/settings.json";
          openRPCPort = true;
          package = pkgs.transmission_4;
          user = "${config.xlib.device.username}";
          group = "users";
          settings = {
            download-dir = "${config.xlib.dirs.server-home}/Downloads";
            incomplete-dir = "${config.xlib.dirs.server-home}/Downloads/Temp";
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
          configDir = "${config.xlib.dirs.storage}/Syncthing/${config.xlib.device.hostname}";
          dataDir = "${config.xlib.dirs.server-home}";
          group = "users";
          user = "${config.xlib.device.username}";
        };
      };

      networking = {
        hostName = "${config.xlib.device.hostname}";
        networkmanager.enable = true;
        firewall.enable = false;
      };

      system = {
        stateVersion = "25.05";
      };
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule

    self.nixosModules.default
    self.homeConfigurations.default.nixosModule
    sops-nix.nixosModules.sops
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "server";
  };
}
