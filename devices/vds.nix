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
      imports = with inputs; [
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")

        ./disko/vds.nix
        disko.nixosModules.disko

        nixos-facter-modules.nixosModules.facter

        self.nixosModules.default
        #self.homeConfigurations.server.nixosModule # home-manager configuration module
      ];

      #facter.reportPath = ./report/facter.json;

      environment.systemPackages = map lib.lowPrio [
        pkgs.curl
        pkgs.gitMinimal
        pkgs.lazygit
      ];

      boot.loader.grub = {
        # no need to set devices, disko will add all devices that have a EF02 partition to the list already
        # devices = [ ];
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      #boot = {
      #kernelPackages = pkgs.linuxPackages_xanmod_stable; # pkgs.linuxPackages_xanmod_stable
      #hardwareScan = true;
      #loader = {
      #  systemd-boot.enable = lib.mkDefault true;
      #  efi.canTouchEfiVariables = lib.mkDefault true;
      #};
      #};

      #swapDevices =
      #  [ { device = "/dev/disk/by-partlabel/disk-main-swap"; }
      #  ];

      users = {
        users = {
          root = {
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P"
            ];
            #++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed
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
        throttled.enable = true;
        journald = {
          extraConfig = ''
            SystemMaxUse=128M
          '';
        };
        # samba = {
        #   enable = true;
        #   settings = {
        #     global = {
        #       "invalid users" = [ ];
        #       "passwd program" = "/run/wrappers/bin/passwd %u";
        #       security = "user";
        #     };
        #     nixos = {
        #       "path" = "/etc/nixos";
        #       "browseable" = "yes";
        #       "read only" = "no";
        #       "valid users" = "${inputs.zeroq.devices.admin}";
        #       "guest ok" = "no";
        #       "writable" = "yes";
        #       "create mask" = 644;
        #       "directory mask" = 644;
        #       "force user" = "${inputs.zeroq.devices.admin}";
        #       "force group" = "users";
        #     };
        #     root = {
        #       "path" = "/";
        #       "browseable" = "yes";
        #       "read only" = "no";
        #       "valid users" = "${inputs.zeroq.devices.admin}";
        #       "guest ok" = "no";
        #       "writable" = "yes";
        #       #"create mask" = 0644;
        #       #"directory mask" = 0644;
        #       "force user" = "root";
        #       "force group" = "root";
        #     };
        #   };
        # };
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
        tailscale.enable = true;
      };

      networking = {
        hostName = "${inputs.zeroq.devices.vds.hostname}";
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
  ];
  system = "x86_64-linux";
}
