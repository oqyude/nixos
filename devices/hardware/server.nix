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
  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
    };
    kernel = {
      sysctl = {
        "fs.inotify.max_user_watches" = "204800";
      };
    };
    kernelModules = [
      "kvm-intel"
      "coretemp"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  #   fileSystems."/" =
  #     { device = "/dev/disk/by-uuid/8acccc34-edc6-4934-886c-ef4b778ca24a";
  #       fsType = "ext4";
  #     };
  #
  #   fileSystems."/boot" =
  #     { device = "/dev/disk/by-uuid/DDF2-C940";
  #       fsType = "vfat";
  #       options = [ "fmask=0022" "dmask=0022" ];
  #     };
  #
  #   fileSystems."/home/otreca/External" =
  #     { device = "/dev/disk/by-uuid/37e53ebc-5343-a94d-9fe2-0ca39e13a8de";
  #       fsType = "ext4";
  #     };

  swapDevices = [ ];

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
