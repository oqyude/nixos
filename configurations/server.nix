{
  deviceType = "server";
  hostname = "sapphira";
  modules = [
    (
      {
        lib,
        pkgs,
        xlib,
        inputs,
        ...
      }:
      {
        imports = [
          ./hardware/server.nix
          inputs.self.nixosModules.default
        ];

        boot = {
          # kernelPackages = pkgs.linuxPackages_xanmod_stable;
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

        fileSystems =
          (xlib.helpers.mkExfatMount {
            path = xlib.dirs.archive-drive;
            label = "archive";
          })
          // (xlib.helpers.mkExfatMount {
            path = xlib.dirs.mobile-drive;
            uuid = "7EB1-DC99";
          })
          // (xlib.helpers.mkBindMount {
            what = xlib.dirs.services-folder;
            where = xlib.dirs.services-mnt-folder;
          })
          // {
            # External drive
            "${xlib.dirs.server-home}" = {
              device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
              fsType = "ext4";
            };
          };

        systemd.tmpfiles.rules = [
          "z ${xlib.dirs.services-mnt-folder} 0777 root root -"
        ];

        xlib.ssh.enable = true;

        networking = {
          networkmanager.enable = true;
          firewall.enable = false;
          # nameservers = [
          #   "192.168.1.1"
          #   "127.0.0.1"
          # ];
        };

        system = {
          stateVersion = "25.05";
        };
      }
    )
  ];
}
