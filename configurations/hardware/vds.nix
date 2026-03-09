{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  fileSystems = {
    "/" = {
      device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root"; # "/dev/disk/by-partlabel/disk-main-root";
      fsType = "ext4";
    };
  };

  # swapDevices = [
  #   { device = "/dev/disk/by-partlabel/disk-main-swap"; }
  # ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
