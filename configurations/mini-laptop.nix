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

        fileSystems."${xlib.dirs.lamet-drive}" = {
          device = "/dev/disk/by-uuid/DC76BD3576BD116E";
          fsType = "ntfs3";
          options = [
            "defaults"
            "uid=1000"
            "gid=1000"
            "fmask=0000"
            "dmask=0000"
            "nofail"
          ];
        };

        xlib.ssh.enable = true;
        hardware.intel-gpu-tools.enable = true;

        system.stateVersion = "26.05";
      }
    )
  ];
}
