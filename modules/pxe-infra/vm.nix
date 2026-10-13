# pxe-infra/vm — QEMU/KVM guest that boots the Alpine worker
# image. The image itself is attached as a local virtio drive
# and the firmware (OVMF) finds the ESP → BOOTX64.EFI →
# kernel on it; the network (pxe0-tap, dnsmasq, nginx, the
# report-sink) is still there for runtime use (the runner
# POSTs to the report-sink, etc.). This replaces an earlier
# design that booted the image over the network via iPXE
# sanboot — iPXE 2.0.0 reliably #GPs at RIP 0x7EE8A5FC
# (RAX=0xAF...AF) when handing off a downloaded 1-2 GB raw
# image back to the firmware under QEMU/OVMF, with or
# without snp.efi and at any reasonable memory size. Since
# the image is already served by nginx at
# `http://10.66.0.1/latest/alpine-worker.raw` for the real
# PXE rig (and the symlink is what deploy.sh updates), the
# local file at that path is the same artifact the PXE rig
# would boot — testing the runner against a direct-boot VM
# is the same test as against a PXE-boot VM once the chain is
# sorted out.
#
# Per docs/ARCHITECTURE.md §L4: the guest is intentionally
# disposable; every run starts from the same state, with no
# persistent disk.
#
# Disposition:
#   - Tap device pxe0-tap is created in the systemd service's
#     pre-start and attached to ${bridge.name}; the systemd
#     unit runs as root so the `ip tuntap add` works without
#     any setuid helper. We use `-netdev tap,ifname=pxe0-tap`
#     rather than `-netdev bridge,br=pxe0` because the latter
#     needs QEMU's qemu-bridge-helper to be setuid (with a
#     matching /etc/qemu/bridge.conf ACL), and the current
#     nixpkgs doesn't ship that wrapper as a NixOS module
#     for ad-hoc QEMU use. The tap+attach pattern is what
#     `qemu-vm.nix` does under the hood for NixOS test VMs.
#   - UEFI firmware via OVMF (UEFI only — B.6), in split
#     CODE+VARS form: OVMF_CODE.fd is mounted read-only, and
#     a writable copy of OVMF_VARS.fd lives at
#     /var/lib/pxe-infra/ovmf-vars.bin. The file is seeded
#     from the nixpkgs OVMF_VARS.fd on the first run and
#     persists across restarts; delete it for a fresh NVRAM.
#   - The Alpine worker image is attached as a virtio drive
#     at the same path nginx serves it from, so the local
#     VM and the PXE rig test the same artifact.
#   - Boot order: disk first (`-boot c`); the firmware finds
#     BOOTX64.EFI in the ESP on the attached image.
#   - `Restart=always` — failed or interrupted runs are safe to
#     repeat without cleanup, per ARCHITECTURE.md §"Run
#     lifecycle". ExecStopPost removes the tap on every stop.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.vm.enable) {
    environment.systemPackages = [ pkgs.qemu ];

    systemd.services.pxe-infra-vm = {
      description = "pxe-infra: PXE-boot QEMU/KVM guest (L4)";
      # Autostart is off by default. The unit still exists, so
      # `systemctl start pxe-infra-vm` is enough to bring the
      # guest up for a test session; `systemctl stop` to tear
      # it down. To bring it up on every boot, set
      # pxe-infra.vm.autostart = true.
      wantedBy = lib.optional config.pxe-infra.vm.autostart "multi-user.target";
      after = [
        "pxe-infra-bridge.service"
        "dnsmasq.service"
        "nginx.service"
        "network-online.target"
      ];
      wants = [
        "pxe-infra-bridge.service"
        "dnsmasq.service"
        "nginx.service"
      ];
      path = [
        pkgs.qemu
        pkgs.iproute2
      ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        # The systemd unit runs as root — needed for the tap
        # creation and bridge attach.
      };

      script = ''
        # Bring up the tap and attach it to the bridge.
        # Idempotent: tear down any previous tap that systemd
        # may have left around after a crash.
        ip link del pxe0-tap 2>/dev/null || true
        ip tuntap add dev pxe0-tap mode tap
        ip link set pxe0-tap master ${config.pxe-infra.bridge.name}
        ip link set pxe0-tap up

        # Seed the OVMF VARS file on first run. See the top
        # comment for why a writable VARS is required.
        VARS=/var/lib/pxe-infra/ovmf-vars.bin
        if [ ! -f "$VARS" ]; then
          cp ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd "$VARS"
        fi

        # bootMode=direct: attach the deployed raw image as a
        # virtio drive, boot from disk. Always works (proven E2E
        # 2026-10-13), and is what the rig should run in steady
        # state since the rig is a pipeline validator, not a
        # test of the iPXE chain itself.
        #
        # bootMode=pxe: no virtio drive, -boot n. The firmware
        # does PXE → dnsmasq hands out DHCP and the iPXE binary
        # → iPXE loads boot.ipxe over HTTP → boot.ipxe boots
        # the image via sanboot/kernel+initrd. This is the
        # path that crashes at iPXE 2.0.0 ExitBootServices
        # (RIP 0x7EE8A5FC, RAX 0xAF...AF). Used to reproduce
        # T10 and verify any fix.
        case "${config.pxe-infra.vm.bootMode}" in
          pxe)
            EXTRA_DRIVES=""
            BOOT_ORDER=n
            ;;
          direct)
            EXTRA_DRIVES="-drive file=${config.pxe-infra.artifacts.root}/http/latest/alpine-worker.raw,format=raw,if=virtio"
            BOOT_ORDER=c
            ;;
          *)
            echo "pxe-infra-vm: unknown bootMode '${config.pxe-infra.vm.bootMode}'" >&2
            exit 1
            ;;
        esac

        exec qemu-system-x86_64 \
          -name pxe-infra-vm \
          -machine type=q35,accel=kvm:tcg \
          -cpu host \
          -smp ${toString config.pxe-infra.vm.cpus} \
          -m ${config.pxe-infra.vm.memory} \
          -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
          -drive if=pflash,format=raw,file=$VARS \
          $EXTRA_DRIVES \
          -netdev tap,id=net0,ifname=pxe0-tap,script=no,downscript=no \
          -device virtio-net-pci,netdev=net0,mac=${config.pxe-infra.vm.mac} \
          -boot $BOOT_ORDER \
          -nographic \
          -serial mon:stdio
      '';

      # Remove the tap on every stop, including crashes and
      # restarts, so the bridge is clean for the next boot.
      postStop = ''
        ip link del pxe0-tap 2>/dev/null || true
      '';
    };
  };
}
