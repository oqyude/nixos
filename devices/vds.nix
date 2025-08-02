{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      modulesPath,
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports =
        with inputs;
        [
          (modulesPath + "/installer/scan/not-detected.nix")
          (modulesPath + "/profiles/qemu-guest.nix")

          ./disko/vds.nix
          ./hardware/vds.nix

          disko.nixosModules.disko
          self.nixosModules.default
        ]
        ++ builtins.attrValues inputs.self.nixosModules.vds;

      environment.systemPackages = map lib.lowPrio [
        pkgs.curl
        pkgs.gitMinimal
        pkgs.lazygit
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

      users = {
        users = {
          root = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P"
            ];
          };
          "${inputs.zeroq.devices.admin}" = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P"
            ];
          };
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
              "valid users" = "${inputs.zeroq.devices.admin}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 755;
              "directory mask" = 755;
              "force user" = "${inputs.zeroq.devices.admin}";
              "force group" = "users";
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
            "${inputs.zeroq.devices.admin}" = {
              "path" = "/home/${inputs.zeroq.devices.admin}";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${inputs.zeroq.devices.admin}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 700;
              "directory mask" = 700;
              "force user" = "${inputs.zeroq.devices.admin}";
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
        hostName = "${inputs.zeroq.devices.vds.hostname}";
        networkmanager.enable = true;
        firewall.enable = true;
      };

      system = {
        stateVersion = "25.05";
      };
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = with inputs; [
    nixosModule
  ];
  system = "x86_64-linux";
}
