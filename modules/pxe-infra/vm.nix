# pxe-infra/vm — QEMU/KVM guest that PXE-boots through the
# private bridge.
#
# Per docs/ARCHITECTURE.md §L4: the guest is intentionally
# disposable; every run starts from the same state, with no
# persistent disk. The boot source is the PXE services on L2/L3
# (dnsmasq for DHCP+TFTP, nginx for HTTP), so the VM is
# essentially a fancier ipxe-compatible client: nothing about
# its state affects the next run.
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
#   - UEFI firmware via OVMF (UEFI only — B.6). The combined
#     `OVMF.fd` is mounted read-only, so the VM has no
#     persistent NVRAM; every restart is a fresh boot, which
#     is the property we want.
#   - Boot order: network only (`-boot n`); no disk, no ISO.
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
      path = [ pkgs.qemu pkgs.iproute2 ];

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

        exec qemu-system-x86_64 \
          -name pxe-infra-vm \
          -machine type=q35,accel=kvm:tcg \
          -cpu host \
          -smp ${toString config.pxe-infra.vm.cpus} \
          -m ${config.pxe-infra.vm.memory} \
          -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF.fd \
          -netdev tap,id=net0,ifname=pxe0-tap \
          -device virtio-net-pci,netdev=net0,mac=${config.pxe-infra.vm.mac} \
          -boot n \
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
