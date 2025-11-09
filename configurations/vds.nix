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
        nameservers = [
          "1.1.1.1"
          "2001:4860:4860::8844"
          "2001:4860:4860::8888"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        hostName = "${xlib.device.hostname}";
        networkmanager.enable = true;
        tempAddresses = "disabled";
        dhcpcd = {
          enable = true;
          IPv6rs = true;
        };
        firewall = {
          enable = true;
          allowPing = true;
        };
        enableIPv6 = true;
        # interfaces.ens3 = {
        #   useDHCP = true;
        #   # ipv4.addresses = [
        #   #   {
        #   #     address = "31.57.158.109";
        #   #     prefixLength = 24;
        #   #   }
        #   # ];
        #   # ipv6.addresses = [
        #   #   {
        #   #     address = "2a13:7c00:10:6:f816:3eff:fe36:fe1b";
        #   #     prefixLength = 64;
        #   #   }
        #   # ];
        # };
        # defaultGateway = {
        #   address = "31.57.158.1";
        #   interface = "ens3";
        # };
        # defaultGateway6 = {
        #   address = "2a13:7c00:10:6::1";
        #   interface = "ens3";
        # };
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
