{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      xlib,
      ...
    }:
    {
      xlib.device = {
        type = "vds";
        hostname = "otreca";
      };

      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")

        ./disko/vds.nix
        ./hardware/vds.nix

        inputs.self.nixosModules.default
      ];

      boot = {
        kernelPackages = pkgs.linuxPackages_xanmod_stable;
        hardwareScan = true;
        loader = {
          grub = {
            enable = true;
            device = "nodev";
            useOSProber = false;
            efiSupport = false;
          };
          systemd-boot.enable = lib.mkDefault false;
        };
      };

      services = {
        earlyoom.enable = true;
        preload.enable = true;
        journald = {
          extraConfig = ''
            
                        SystemMaxUse=512M
          '';
        };
        samba = {
          enable = true;
          openFirewall = true;
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
              "valid users" = "${xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 755;
              "directory mask" = 755;
              "force user" = "${xlib.device.username}";
              "force group" = "users";
            };
            root = {
              "path" = "/";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              #"create mask" = 0644;
              #"directory mask" = 0644;
              "force user" = "root";
              "force group" = "root";
            };
            "${xlib.device.username}" = {
              "path" = "/home/${xlib.device.username}";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 700;
              "directory mask" = 700;
              "force user" = "${xlib.device.username}";
              "force group" = "users";
            };
          };
        };
        openssh = {
          enable = true;
          allowSFTP = true;
          openFirewall = true;
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
        tailscale = {
          enable = true;
          openFirewall = true;
        };
      };

      networking = {
        hostName = "${xlib.device.hostname}";
        networkmanager.enable = true;
        firewall.enable = true;
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
    deviceType = "vds";
  };
}
