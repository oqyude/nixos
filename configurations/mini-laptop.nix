{
  deviceType = "secondary";
  hostname = "rydiwo";
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
        imports = with inputs; [
          nixos-hardware.nixosModules.chuwi-minibook-x
          ./hardware/mini-laptop.nix
          self.nixosModules.default
        ];

        boot = {
          kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
          loader = {
            systemd-boot.enable = lib.mkDefault true;
            efi.canTouchEfiVariables = lib.mkDefault true;
          };
        };

        fileSystems = xlib.helpers.mkNtfsMount {
          path = xlib.dirs.lamet-drive;
          uuid = "DC76BD3576BD116E";
          mask = "0000";
        };

        xlib.ssh.enable = true;
        hardware.intel-gpu-tools.enable = true;

        system.stateVersion = "26.05";
      }
    )
  ];
}
