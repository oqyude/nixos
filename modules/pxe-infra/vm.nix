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
#   - Bridge attach via `-netdev bridge,br=pxe0`; this requires
#     CAP_NET_ADMIN, which the systemd unit has as root.
#   - UEFI firmware via OVMF (UEFI only — B.6). The combined
#     `OVMF.fd` is mounted read-only, so the VM has no
#     persistent NVRAM; every restart is a fresh boot, which is
#     the property we want.
#   - Boot order: network only (`-boot n`); no disk, no ISO.
#   - `Restart=always` — failed or interrupted runs are safe to
#     repeat without cleanup, per ARCHITECTURE.md §"Run
#     lifecycle".
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
      path = [ pkgs.qemu ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        # The systemd unit runs as root — needed for the bridge
        # attach (`-netdev bridge,br=...`).
      };

      script = ''
        exec qemu-system-x86_64 \
          -name pxe-infra-vm \
          -machine type=q35,accel=kvm:tcg \
          -cpu host \
          -smp ${toString config.pxe-infra.vm.cpus} \
          -m ${config.pxe-infra.vm.memory} \
          -drive if=pflash,format=raw,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF.fd \
          -netdev bridge,id=net0,br=${config.pxe-infra.bridge.name} \
          -device virtio-net-pci,netdev=net0,mac=${config.pxe-infra.vm.mac} \
          -boot n \
          -nographic \
          -serial mon:stdio
      '';
    };
  };
}
