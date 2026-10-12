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
    ./ipxe.nix
    ./report-sink.nix
    ./vm.nix
  ];

  config = lib.mkIf config.pxe-infra.enable {
    # Create the artifact directory tree at boot. TFTP and HTTP
    # both serve from here; the actual artifacts land in this tree
    # by whatever means (manual copy, deploy step, mkosi output
    # directory — see docs/OPEN-QUESTIONS.md B.9/B.10).
    #
    # The `L+` rules symlink the iPXE binary and boot.ipxe script
    # from /etc/static/pxe-infra/... (where the ipxe.nix module
    # drops them via environment.etc) into the served roots, so
    # `nixos-rebuild` upgrades of pkgs.ipxe are picked up at the
    # next boot without redeploying anything.
    systemd.tmpfiles.rules = [
      "d ${config.pxe-infra.artifacts.root} 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/http 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/tftpboot 0755 root root - -"
      "L+ ${config.pxe-infra.artifacts.root}/tftpboot/${config.pxe-infra.bootloader.ipxeBinary} - - - - /etc/static/pxe-infra/tftpboot/${config.pxe-infra.bootloader.ipxeBinary}"
      "L+ ${config.pxe-infra.artifacts.root}/http/boot.ipxe - - - - /etc/static/pxe-infra/http/boot.ipxe"
    ];
  };
}
