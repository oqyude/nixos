{
  config,
  lib,
  pkgs,
  modulesPath,
  xlib,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usb_storage"
      "uas"
      "usbhid"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
      "amdgpu"
    ];
    extraModulePackages = [ ];
  };

  # hardware = {
  #   amdgpu = {
  #     opencl.enable = true;
  #   };
  #   graphics.extraPackages = with pkgs; [
  #     mesa
  #     amf
  #   ];
  # };
  # systemd.tmpfiles.rules = [
  #   "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  # ];

  fileSystems = {
    "/" = {
      #device = "/dev/disk/by-partlabel/disk-${xlib.device.hostname}-root";
      device = "/dev/disk/by-partuuid/50213d1b-ec8c-4d8d-a4e5-1fd0ee204687";
      fsType = "ext4";
    };
    "/boot" = {
      #device = "/dev/disk/by-partlabel/disk-${xlib.device.hostname}-ESP";
      device = "/dev/disk/by-partuuid/b3aeb2c4-ace5-4764-8479-12b223c701ba";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  # swapDevices = [
  #   { device = "/dev/disk/by-partlabel/disk-${xlib.device.hostname}-swap"; }
  # ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp100s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp98s0.useDHCP = lib.mkDefault true;

  #nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
