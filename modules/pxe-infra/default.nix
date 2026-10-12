# pxe-infra — isolated private network for PXE VM guests (L2/L3 of
# docs/ARCHITECTURE.md). Provides a Linux bridge, a MAC-filtered
# DHCP server, a TFTP server (iPXE bootloader), and an HTTP server
# (kernel/initramfs/rootfs), so a fresh VM can netboot from this
# host without touching the real LAN.
#
# Master toggle: `pxe-infra.enable`. Submodules guard their own
# config with `lib.mkIf config.pxe-infra.enable`, so importing
# this umbrella alone has no effect on a host that opts out.
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./bridge.nix
    ./dhcp.nix
    ./http.nix
    ./vm.nix
  ];

  config = lib.mkIf config.pxe-infra.enable {
    # Create the artifact directory tree at boot. TFTP and HTTP
    # both serve from here; the actual artifacts land in this tree
    # by whatever means (manual copy, deploy step, mkosi output
    # directory — see docs/OPEN-QUESTIONS.md B.9/B.10).
    systemd.tmpfiles.rules = [
      "d ${config.pxe-infra.artifacts.root} 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/http 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/tftpboot 0755 root root - -"
    ];
  };
}
