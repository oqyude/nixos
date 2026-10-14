# pxe-infra/ipxe — stage the iPXE EFI binary into the TFTP root
# and write a static boot.ipxe script into the HTTP root.
#
# Together with the `dhcp-boot` option configured in dhcp.nix,
# this completes the boot chain:
#   UEFI firmware
#     → TFTP:  artifacts.root/tftpboot/<ipxeBinary>
#     → runs iPXE
#     → HTTP:  http://<bridge.address>/boot.ipxe
#     → iPXE script sanboots the alpine-worker raw disk image
#
# The artifact itself is produced by build/mkosi/ in the
# pxe-infra-automation repo and rsynced into
# artifacts.root/http/<rev>/. A `latest/` symlink points at the
# newest <rev>, which the static boot.ipxe references.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.bootloader.enable) {
    # iPXE binary from nixpkgs. We drop it under
    # /etc/static/pxe-infra/tftpboot/ via environment.etc; the
    # tmpfiles rule in default.nix symlinks from there into the
    # actual served TFTP root.
    environment.etc."pxe-infra/tftpboot/${config.pxe-infra.bootloader.ipxeBinary}".source =
      "${pkgs.ipxe}/${config.pxe-infra.bootloader.ipxeBinary}";

    # Static iPXE script, served by the L3 HTTP server. iPXE
    # fetches it via HTTP after the initial TFTP-boot of the
    # binary itself.
    #
    # `''${...}''` is Nix's escape for a literal `${...}` in a
    # multi-line string; iPXE uses `${boot-url}` as its own
    # variable substitution, which must survive into the output
    # verbatim.
    environment.etc."pxe-infra/http/boot.ipxe".source = pkgs.writeText "boot.ipxe" ''
      #!ipxe
      set boot-url http://${config.pxe-infra.bridge.address}/latest
      # Test path: bypass sanboot entirely. Load the Alpine
      # kernel and initrd from HTTP and hand off to UEFI. We
      # expect the kernel to panic on rootfs (no /dev/sda*
      # in this build), but the journal will show kernel boot
      # output — enough to confirm iPXE's kernel/initrd/boot
      # path works and rule out iPXE's HTTP/sanboot code as
      # the source of the persistent #GP at RIP 0x7EE8A5FC.
      kernel ''${boot-url}/vmlinuz-virt root=/dev/ram0 console=ttyS0,115200
      initrd ''${boot-url}/initramfs-virt
      boot || goto retry
      :retry
      echo boot failed, retrying in 5s
      sleep 5
      kernel ''${boot-url}/vmlinuz-virt root=/dev/ram0 console=ttyS0,115200
      initrd ''${boot-url}/initramfs-virt
      boot
    '';
    # autoexec.ipxe — iPXE on UEFI looks for `autoexec.ipxe` on the
    # same TFTP server it was loaded from, and runs it as the boot
    # script. Without it, the iPXE instance that replaced the
    # firmware PXE ROM has nothing to chain to and ends up in
    # "No more network devices" -> #GP (T10). This is a one-liner
    # that bridges to the HTTP-served boot.ipxe.
    #
    # Discovered 2026-10-14 via the H1 reproduction in
    # .agent/notes/T10-diagnostic-2026-10-14.md (pxe-infra-automation
    # repo): the RIP at 0x7EC9456F was a different crash site
    # than the previously-recorded 0x7EE8A5FC -- iPXE was dying
    # before even reaching boot.ipxe.
    environment.etc."pxe-infra/tftpboot/autoexec.ipxe".source =
      pkgs.writeText "autoexec.ipxe" '''#!ipxe
chain http://${config.pxe-infra.bridge.address}/boot.ipxe
''';
  };
}
