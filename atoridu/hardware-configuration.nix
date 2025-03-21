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
      kernelModules = [ ];
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "uas"
        "sd_mod"
      ];
    };
    kernelModules = [ "kvm-amd" ];
    #kernelParams = [ "i915.force_probe=46d1" ];
    extraModulePackages = [ ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    #cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
    graphics = {
      enable = true;
      #extraPackages = with pkgs; [ vaapiIntel intel-media-driver ];
    };
    bluetooth.enable = true;
    alsa.enable = false;
    nvidia = {
      open = true;
      dynamicBoost.enable = true;
      nvidiaSettings = true;
      powerManagement = {
        enable = true;
        finegrained = false; # maybe comment this out idk what it does
      };
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaPersistenced = true;
      modesetting.enable = true;
      prime = {
        offload.enable = true;
        sync.enable = false;
        amdgpuBusId = "PCI:6:0:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/5938c796-6ff5-49d9-a3a6-022b4c32beeb";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/61BF-3342";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/mnt/sound" = {
      device = "/dev/disk/by-uuid/C0A2DDEFA2DDEA44";
      fsType = "ntfs3";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d89bccd2-0672-4855-9d87-40e2688cdec4"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
