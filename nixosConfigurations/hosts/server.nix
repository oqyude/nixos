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
      ];

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

      fileSystems = {
        # External drive
        "${config.xlib.dirs.server-home}" = {
          device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
          fsType = "ext4";
          options = [
            #"nofail"
            #"x-systemd.device-timeout=0"
          ];
        };
        # Archive drive
        "/mnt/archive" = {
          device = "/dev/disk/by-label/archive";
          fsType = "exfat";
          options = [
            "nofail"
            #"x-systemd.device-timeout=0"
            "uid=1000"
            "gid=1000"
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
  modules = [
    nixosModule

    inputs.self.nixosModules.default
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "server";
  };
}
