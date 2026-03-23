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
        type = "vds-new";
        hostname = "otreca-new";
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
        journald = {
          extraConfig = ''
            SystemMaxUse=512M
          '';
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
          "8.8.8.8"
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
        interfaces.ens3 = {
          useDHCP = true;
          # ipv4.addresses = [
          #   {
          #     address = "31.57.158.109";
          #     prefixLength = 24;
          #   }
          # ];
          # ipv6.addresses = [
          #   {
          #     address = "2a13:7c00:6:102:f816:3eff:fe91:6b9e";
          #     prefixLength = 64;
          #   }
          # ];
        };
        # defaultGateway = {
        #   address = "31.57.158.1";
        #   interface = "ens3";
        # };
        # defaultGateway6 = {
        #   address = "2a13:7c00:6:102::1";
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
    deviceType = "vds-new";
  };
}
