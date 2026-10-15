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
# artifacts.root/http/<rev>/. A `latest/` symlink points at the
# newest <rev>, which boot.ipxe references.
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
