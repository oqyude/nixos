{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  #  boot = {
  #     initrd = {
  #       availableKernelModules = [
  #         "ahci"
  #         "xhci_pci"
  #         "usbhid"
  #         "usb_storage"
  #         "sd_mod"
  #         "sdhci_pci"
  #       ];
  #     };
  #     kernel = {
  #       sysctl = {
  #         "fs.inotify.max_user_watches" = "204800";
  #       };
  #     };
  #     kernelModules = [
  #       "kvm-intel"
  #       "coretemp"
  #     ];
  #  };

  fileSystems = {
    "/" = {
      device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root"; # "/dev/disk/by-partlabel/disk-main-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = lib.mkForce "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  #       swapDevices = [
  #         { device = "/dev/disk/by-partlabel/disk-main-swap"; }
  #       ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.tailscale0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
