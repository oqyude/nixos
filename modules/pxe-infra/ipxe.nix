# pxe-infra/ipxe — stage the iPXE EFI binary into the TFTP root
# and write static boot scripts into the HTTP root.
#
# Together with the `dhcp-boot` option configured in dhcp.nix,
# this completes the boot chain:
#   UEFI firmware
#     → TFTP:  artifacts.root/tftpboot/<ipxeBinary>
#     → runs iPXE
#     → HTTP:  http://<bridge.address>/<chain-target>
#     → iPXE script loads the kernel and the initramfs over HTTP; the
#       initramfs carries the read-only squashfs rootfs inside itself
#       (production path: boot.ipxe; legacy disk path: boot-bypass.ipxe)
#
# Two static scripts are staged under artifacts.root/http/:
#   - boot.ipxe        — the production chain (kernel + initrd; the
#                        initramfs carries the read-only rootfs)
#   - boot-bypass.ipxe — the legacy disk-profile chain (kernel+initrd
#                        with the image attached as a local disk)
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

    # Static iPXE script — PRODUCTION CHAIN (read-only payload).
    #
    # The worker payload is a read-only squashfs rootfs that travels
    # INSIDE the initramfs (build/alpine-worker/build-squashfs.sh in the
    # pxe-infra-automation repo). The guest therefore needs no disk and
    # no root UUID: the chain loads the kernel and the initramfs over
    # HTTP, and the initramfs attaches the embedded squashfs through a
    # loop device, mounts it READ-ONLY, makes /etc and /var writable in
    # RAM (overlayfs) and switch_root()s into the worker system.
    #
    # This replaces the previous `sanboot .../alpine-worker.raw` chain,
    # which depended on iPXE's SAN-boot extensions - the dependency
    # behind T14 (the 6.18.57 PCI-match regression) and risk R1 (SAN
    # under ESXi EFI, never verified). The disk profile (build.sh) and
    # its sanboot chain remain as the legacy/regression path, reachable
    # through boot-bypass.ipxe.
    #
    # `''${...}` is Nix's escape for a literal `${...}` in a
    # multi-line string; iPXE uses `${boot-url}` as its own
    # variable substitution, which must survive into the output
    # verbatim.
    environment.etc."pxe-infra/http/boot.ipxe".source = pkgs.writeText "boot.ipxe" ''
      #!ipxe
      set boot-url http://${config.pxe-infra.bridge.address}/latest
      kernel ''${boot-url}/vmlinuz-virt console=ttyS0,115200n8 console=tty0
      initrd ''${boot-url}/initramfs-virt
      boot || goto retry
      :retry
      echo boot failed, retrying in 5s
      sleep 5
      kernel ''${boot-url}/vmlinuz-virt console=ttyS0,115200n8 console=tty0
      initrd ''${boot-url}/initramfs-virt
      boot || goto shell
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
    environment.etc."pxe-infra/tftpboot/autoexec.ipxe".source = pkgs.writeText "autoexec.ipxe" ''
      #!ipxe
      echo === ifstat ===
      ifstat
      echo === route ===
      route
      echo === ping ===
      ping --count=2 ${config.pxe-infra.bridge.address} || echo PING_FAILED
      echo === chain ===
      chain http://${config.pxe-infra.bridge.address}/${
        if config.pxe-infra.bootloader.bypassFallback.enable then "boot-bypass.ipxe" else "boot.ipxe"
      }
    '';
  };
}
