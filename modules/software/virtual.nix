{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    kernelModules = [
      "kvm-amd"
      "vfio"
      "vfio-pci"
      "vfio_iommu_type1"
      "vfio_virqfd"
    ];
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
    ];
  };
  services = {
    spice-vdagentd.enable = true;
  };
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  environment = {
    systemPackages = with pkgs; [
      spice
      #spice-gtk
      #spice-protocol
      virt-manager
      virt-viewer
      virtiofsd
      win-spice
      virtio-win
      #looking-glass-client # pci-passthrough
    ];
  };
}
