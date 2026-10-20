# pxe-infra/ipxe — stage the iPXE EFI binary into the TFTP root
# and write static boot scripts into the HTTP root.
#
# Together with the `dhcp-boot` option configured in dhcp.nix,
# this completes the boot chain:
#   UEFI firmware
#     → TFTP:  artifacts.root/tftpboot/<ipxeBinary>
#     → runs iPXE
#     → HTTP:  http://<bridge.address>/<chain-target>
#     → iPXE script sanboots the alpine-worker raw disk image
#       (production path: boot.ipxe; regression path: boot-bypass.ipxe)
#
# Two static scripts are staged under artifacts.root/http/:
#   - boot.ipxe        — the production sanboot chain
#   - boot-bypass.ipxe — the H_fix.1b regression baseline
#                        (kernel+initrd, no sanboot)
# Which one autoexec.ipxe chains to is controlled by
# `pxe-infra.bootloader.bypassFallback.enable` (see default.nix).
#
# The artifact itself is produced by build/mkosi/ in the
# pxe-infra-automation repo and rsynced into
# artifacts.root/http/<rev>/. `latest/` is a real directory holding
# the published artifact (published with a rename(2), so it is
# atomic), and boot.ipxe references it.
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

    # Static iPXE script — PRODUCTION SANBOOT PATH.
    #
    # This is the script autoexec.ipxe chains to by default
    # (`pxe-infra.bootloader.bypassFallback.enable = false`).
    # It sanboots the alpine-worker raw disk image and lets
    # OVMF re-enter boot services so the image's ESP-resident
    # systemd-boot (`BOOTX64.EFI` + `loader/loader.conf`)
    # finishes the chain. The image is already sanboot-ready
    # — verified by H_fix.2-3 against
    # `build/alpine-worker/build.sh:135-185`.
    #
    # The companion `boot-bypass.ipxe` (staged below) is the
    # H_fix.1b regression baseline: it bypasses sanboot
    # entirely and uses the kernel+initrd path, which we know
    # reaches the Alpine Init shell (T10). It is kept reachable
    # behind `bypassFallback.enable` so a future regression
    # in the sanboot chain can be reproduced with a single
    # config flip + rebuild, without touching this file.
    # autoexec.ipxe (further down) selects which of the two
    # scripts to chain to based on that option.
    #
    # `''${...}''` is Nix's escape for a literal `${...}` in a
    # multi-line string; iPXE uses `${boot-url}` as its own
    # variable substitution, which must survive into the output
    # verbatim.
    environment.etc."pxe-infra/http/boot.ipxe".source = pkgs.writeText "boot.ipxe" ''
      #!ipxe
      set boot-url http://${config.pxe-infra.bridge.address}/latest
      sanboot ''${boot-url}/alpine-worker.raw || goto retry_alpine
      :retry_alpine
      echo sanboot failed, retrying in 5s
      sleep 5
      sanboot ''${boot-url}/alpine-worker.raw || goto shell
      :shell
      shell
    '';

    # Static iPXE script — H_fix.1b REGRESSION BASELINE.
    #
    # This is the original kernel+initrd bypass path, preserved
    # byte-identical to the pre-split boot.ipxe content (the
    # body matches `.agent/notes/T10-diagnostic-2026-10-14.md`
    # lines 130-142 and
    # `.agent/notes/T10-h-fix-1b-pxe-with-autoexec-2026-10-14.log`
    # regression shape). It bypasses sanboot entirely; the
    # kernel panics on rootfs (no /dev/sda* in this build),
    # but the journal shows kernel boot output — enough to
    # confirm iPXE's chain works end-to-end and rule out
    # iPXE's HTTP/sanboot code as the source of any persistent
    # #GP.
    #
    # autoexec.ipxe chains to this script when
    # `pxe-infra.bootloader.bypassFallback.enable = true`.
    # Both scripts are always staged (no mkIf gate) so the
    # chain target can be swapped with a config flip + rebuild
    # without re-deploying artifacts.
    #
    # `''${...}''` is Nix's escape for a literal `${...}` in a
    # multi-line string; iPXE uses `${boot-url}` as its own
    # variable substitution, which must survive into the output
    # verbatim.
    environment.etc."pxe-infra/http/boot-bypass.ipxe".source = pkgs.writeText "boot-bypass.ipxe" ''
      #!ipxe
      set boot-url http://${config.pxe-infra.bridge.address}/latest
      # KERNEL+INITRD PATH (no sanboot). Loads the Alpine kernel and
      # initramfs over HTTP and hands off to them.
      #
      # The guest still needs the image attached as a local block
      # device: the root filesystem lives on the image's ext4 partition
      # (vda2), not inside the initramfs. In direct mode the VM gets
      # it from EXTRA_DRIVES (see vm.nix); in this path it has to be
      # attached the same way.
      #
      # The root filesystem is addressed by UUID, and a kernel booted
      # over HTTP has no loader entry to supply it, so the UUID is
      # fetched at runtime from the HTTP root (published next to the
      # image by the pxe-infra-automation deploy script). The first
      # attempt at this path used `root=/dev/ram0` and failed with
      # "mounting /dev/ram0 on /sysroot failed" - the root is the
      # image's ext4 partition, not a ramdisk.
      #
      # This path is what makes the rig usable on firmware without
      # INT13 SAN extensions, where iPXE's sanboot does not work.
      isset ''${root-uuid} ''${boot-url}/root-uuid.txt || goto no_uuid
      kernel ''${boot-url}/vmlinuz-virt root=UUID=''${root-uuid} rootfstype=ext4 modules=kms,scsi,virtio console=ttyS0,115200n8 console=tty0
      initrd ''${boot-url}/initramfs-virt
      boot || goto retry
      :retry
      echo boot failed, retrying in 5s
      sleep 5
      kernel ''${boot-url}/vmlinuz-virt root=UUID=''${root-uuid} rootfstype=ext4 modules=kms,scsi,virtio console=ttyS0,115200n8 console=tty0
      initrd ''${boot-url}/initramfs-virt
      boot || goto shell
      :no_uuid
      echo could not fetch ''${boot-url}/root-uuid.txt
      :shell
      shell
    '';

    # autoexec.ipxe — iPXE on UEFI looks for `autoexec.ipxe` on the
    # same TFTP server it was loaded from, and runs it as the boot
    # script. Without it, the iPXE instance that replaced the
    # firmware PXE ROM has nothing to chain to and ends up in
    # "No more network devices" -> #GP (T10). This is a one-liner
    # that bridges to the HTTP-served chain target.
    #
    # Chain target depends on
    # `pxe-infra.bootloader.bypassFallback.enable`:
    #   false (default) → boot.ipxe
    #                    (production sanboot path)
    #   true            → boot-bypass.ipxe
    #                    (H_fix.1b regression baseline)
    #
    # Discovered 2026-10-14 via the H1 reproduction in
    # .agent/notes/T10-diagnostic-2026-10-14.md (pxe-infra-automation
    # repo): the RIP at 0x7EC9456F was a different crash site
    # than the previously-recorded 0x7EE8A5FC -- iPXE was dying
    # before even reaching boot.ipxe.
    environment.etc."pxe-infra/tftpboot/autoexec.ipxe".source =
      pkgs.writeText "autoexec.ipxe" ''#!ipxe
chain http://${config.pxe-infra.bridge.address}/${if config.pxe-infra.bootloader.bypassFallback.enable then "boot-bypass.ipxe" else "boot.ipxe"}
'';
  };
}
