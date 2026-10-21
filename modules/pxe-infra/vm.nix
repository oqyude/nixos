# pxe-infra/vm — QEMU/KVM guest that boots the Alpine worker
# image. The image itself is attached as a local virtio drive
# (bootMode=direct) or fetched over the network via iPXE
# (bootMode=pxe). The network (pxe0 bridge, dnsmasq, nginx,
# the report-sink) is used for both runtime (runner POSTs to
# the report-sink) and PXE boot.
#
# Per docs/ARCHITECTURE.md §L4: the guest is intentionally
# disposable; every run starts from the same state, with no
# persistent disk.
#
# Network disposition:
#   - -netdev bridge attaches the VM's NIC directly to the
#     pxe0 bridge. This is the standard pattern, equivalent
#     to what `qemu-vm.nix` does for NixOS test VMs.
#   - QEMU's qemu-bridge-helper must be setuid root to create
#     the TAP device and attach it to the bridge. We use
#     NixOS `security.wrappers` to create a setuid wrapper at
#     /run/wrappers/bin/qemu-bridge-helper that execs the
#     nixpkgs-provided binary. The helper path is passed
#     explicitly via the `helper=` option on -netdev.
#   - /etc/qemu/bridge.conf restricts which bridges the helper
#     may attach to (just pxe0 here). Without this, the helper
#     would refuse to run.
#   - As of 2026-10-14, the `security.wrappers` activation
#     script in this NixOS version doesn't always apply the
#     setuid bit (observed: wrapper created with mode 0511
#     after activation). A `z` tmpfiles rule re-applies 4755
#     if the file exists, guaranteeing the setuid bit after
#     every activation. This is a workaround; the proper fix
#     is upstream in NixOS.
#
# bootMode=direct (default): attach the deployed raw image as
# a virtio drive, boot from disk. Always works (proven E2E
# 2026-10-13), and is what the rig should run in steady state
# since the rig is a pipeline validator, not a test of the
# iPXE chain itself.
#
# bootMode=pxe: no virtio drive, -boot n. The firmware does
# PXE → dnsmasq hands out DHCP and the iPXE binary → iPXE
# loads boot.ipxe over HTTP → boot.ipxe boots the image via
# sanboot/kernel+initrd. Since 2026-10-14 (T10 fix:
# autoexec.ipxe on TFTP root), this path works end-to-end.
#
# UEFI firmware via OVMF (UEFI only — B.6), in split CODE+VARS
# form: OVMF_CODE.fd is mounted read-only, and a writable copy
# of OVMF_VARS.fd lives at /var/lib/pxe-infra/ovmf-vars.bin.
# The file is seeded from the nixpkgs OVMF_VARS.fd on the
# first run and persists across restarts; delete it for a
# fresh NVRAM.
#
# Restart=always — failed or interrupted runs are safe to
# repeat without cleanup, per ARCHITECTURE.md §"Run lifecycle".
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.vm.enable) {
    environment.systemPackages = [ pkgs.qemu ];

    # Setuid wrapper for qemu-bridge-helper. QEMU invokes this
    # binary to create the TAP device and attach it to the
    # bridge, which requires CAP_NET_ADMIN. The wrapper is a
    # small C program that execs the nixpkgs-provided binary
    # as root, and the wrapper itself is setuid root. Placed
    # in /run/wrappers/bin/ and referenced explicitly via
    # `helper=` on -netdev below.
    security.wrappers.qemu-bridge-helper = {
      source = "${pkgs.qemu}/libexec/qemu-bridge-helper";
      owner = "root";
      group = "root";
      permissions = "u+rx,g+x,o+x";
    };

    # Restrict qemu-bridge-helper to our private bridge only.
    # Without an `allow` line, the helper refuses to attach to
    # any bridge.
    environment.etc."qemu/bridge.conf".text = ''
      allow ${config.pxe-infra.bridge.name}
    '';

    # Force setuid on the qemu-bridge-helper wrapper. The
    # `security.wrappers` activation script in this NixOS
    # version doesn't always apply the setuid bit (observed
    # 2026-10-14: mode 0511 after activation, which makes
    # qemu-bridge-helper fail to create the TAP). A tmpfiles
    # `z` rule doesn't help because security.wrappers creates
    # the wrapper AFTER tmpfiles runs. ExecStartPre in the
    # service below runs every time the VM starts and
    # guarantees the setuid bit is set before qemu invokes
    # the helper. Remove this once upstream NixOS is fixed.

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
        # qemu-bridge-helper setuid wrapper, see above.
        "/run/wrappers/bin"
      ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
      };


      script = ''
        # Ensure the qemu-bridge-helper wrapper is setuid. The
        # `security.wrappers` activation script in this NixOS
        # version doesn't always apply the setuid bit, so we
        # re-apply it here at every VM start. Runs as root
        # (system service), so chmod 4755 works. Remove once
        # upstream NixOS is fixed.
        if [ -f /run/wrappers/bin/qemu-bridge-helper ]; then
          chmod 4755 /run/wrappers/bin/qemu-bridge-helper
        fi

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
        # the image via sanboot/kernel+initrd. Since 2026-10-14
        # (T10 fix: autoexec.ipxe on TFTP root), this path works
        # end-to-end.
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
          -netdev bridge,id=net0,br=${config.pxe-infra.bridge.name},helper=/run/wrappers/bin/qemu-bridge-helper \
          # e1000, NOT virtio-net-pci (T24, 2026-10-21).
          #
          # With virtio-net the guest's OVMF claims the device with its
          # OWN virtio-net driver and does not expose an SNP handle, so
          # iPXE falls back to ITS OWN virtio-net driver - and cannot
          # open the device, because the firmware already holds it:
          #   net0: ... using virtio-net on 0000:00:02.0 (Ethernet) [closed]
          #   route: net0: 10.66.0.10/255.255.255.0 gw 10.66.0.1 (inaccessible)
          #   http://10.66.0.1/boot.ipxe... Network unreachable
          # The interface is closed, so no route is usable and every
          # HTTP fetch fails - the chain dies before the payload.
          #
          # With e1000 the firmware exposes SNP, iPXE uses the
          # firmware's path ("using 82540em ... [open]"), the routes are
          # usable and the chain works end to end.
          #
          # The guest kernel is unaffected: linux-virt ships e1000.ko and
          # the worker payload loads it from the read-only rootfs.
          -device e1000,netdev=net0,mac=${config.pxe-infra.vm.mac} \
          -boot $BOOT_ORDER \
          -nographic \
          -serial mon:stdio
      '';

      # No postStop cleanup needed — qemu-bridge-helper handles
      # TAP teardown when qemu exits. The systemd Restart=always
      # + RestartSec=5s loop picks up from the next start.
    };
  };
}