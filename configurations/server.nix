{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      xlib,
      ...
    }:
    {
      xlib.device = {
        type = "server";
        hostname = "sapphira";
      };

      imports = [
        ./hardware/server.nix
        inputs.self.nixosModules.default
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
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-ocl
            intel-vaapi-driver
          ];
        };
        intel-gpu-tools.enable = true;
      };

      # swapDevices = [
      #   { device = "/dev/disk/by-partlabel/disk-main-swap"; }
      # ];

      fileSystems = {
        # External drive
        "${xlib.dirs.server-home}" = {
          device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
          fsType = "ext4";
        };
        # Archive drive
        "/mnt/archive" = {
          device = "/dev/disk/by-label/archive";
          fsType = "exfat";
          options = [
            "nofail"
            "uid=1000"
            "gid=1000"
          ];
        };
        # Mobile SD-Card
        "/mnt/mobile" = {
          device = "/dev/disk/by-uuid/7EB1-DC99";
          fsType = "exfat";
          options = [
            "nofail"
            "uid=1000"
            "gid=1000"
          ];
        };
        "${xlib.dirs.services-mnt-folder}" = {
          device = "${xlib.dirs.services-folder}";
          options = [
            "bind"
            "nofail"
            # "uid=1000"
            # "gid=1000"
            # "fmask=0000"
            # "dmask=0000"
          ];
        };
      };

      systemd.tmpfiles.rules = [
        "z ${xlib.dirs.services-mnt-folder} 0777 root root -"
      ];

      services = {
        power-profiles-daemon.enable = lib.mkForce false;
        earlyoom.enable = true;
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
        hostName = "${xlib.device.hostname}";
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
  ];
  system = "x86_64-linux";
  specialArgs = {
    deviceType = "server";
  };
}
