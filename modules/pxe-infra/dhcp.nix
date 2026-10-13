# pxe-infra/dhcp — dnsmasq as a DHCP-only server bound to the
# private bridge, never touching the LAN.
#
# Hard rules (per docs/ARCHITECTURE.md L2):
#   - bind to the bridge interface only
#   - never resolve DNS (port = 0 disables the DNS server)
#   - when authoritative = false (default), only respond to DHCP
#     requests for MACs listed in pxe-infra.dhcp.guests;
#     everything else is silently dropped.
#
# Together these make the rig a stand-in DHCP server for the VM
# only; the real LAN's DHCP server stays authoritative for
# everything else and the bridge cannot become a second source
# of leases on the LAN.
{
  config,
  lib,
  ...
}:
let
  cfg = config.pxe-infra.dhcp;
  bridgeName = config.pxe-infra.bridge.name;

  # Build dhcp-host entries with a `known` tag attached, so when
  # authoritative = false we can drop everything else.
  dhcpHostLines = map
    (g:
      let
        body = if g.hostname != null
          then "${g.mac},${g.ip},${g.hostname}"
          else "${g.mac},${g.ip}";
      in "${body},set:known")
    cfg.guests;

  # Free address pool. Always set so dnsmasq actually opens
  # its DHCP server socket — without a `dhcp-range` line, dnsmasq
  # silently runs TFTP only and the UEFI firmware's DHCP DISCOVER
  # times out. The range is gated by the MAC filter
  # (dhcp-ignore=tag:!known) below, so unknown MACs never see a
  # lease, but the range must exist.
  dhcp-range =
    if cfg.rangeStart != null && cfg.rangeEnd != null
    then [ "${cfg.rangeStart},${cfg.rangeEnd},${cfg.leaseTime}" ]
    # Default: the entire bridge subnet minus the host address.
    # Hardcoded for /24 because the bridge defaults to
    # 10.66.0.1/24; if the bridge address/prefix changes,
    # update this default.
    else [ "10.66.0.2,10.66.0.254,12h" ];

  base = {
    # Bind to the private bridge only — never 0.0.0.0, never eth0.
    bind-interfaces = true;
    interface = [ bridgeName ];
    # DHCP-only — kill the DNS server entirely.
    port = 0;
    # Don't read resolv.conf, don't poll it.
    no-resolv = true;
    no-poll = true;
    # No cache (no DNS queries to cache anyway).
    cache-size = 0;
    # Logging.
    log-dhcp = true;
    log-queries = false;
    log-facility = "-";
    # Static reservations.
    dhcp-host = dhcpHostLines;
  };

  # Optional TFTP module on the same dnsmasq instance. Used to
  # hand out the iPXE bootloader (a few hundred KB) before the
  # client switches to HTTP for the kernel/initramfs/rootfs.
  tftpSettings = lib.optionalAttrs config.pxe-infra.tftp.enable {
    enable-tftp = true;
    tftp-root = "${config.pxe-infra.artifacts.root}/tftpboot";
  };

  # Boot filename: when the iPXE binary is staged, hand it to
  # UEFI firmware in the DHCP offer so the firmware knows what
  # to TFTP-fetch. Sent to all clients; the `tag:!known` filter
  # below still drops requests from unknown MACs.
  bootSettings = lib.optionalAttrs (config.pxe-infra.tftp.enable && config.pxe-infra.bootloader.enable) {
    dhcp-boot = config.pxe-infra.bootloader.ipxeBinary;
  };

  filtered = base // tftpSettings // bootSettings // lib.optionalAttrs (!cfg.authoritative) {
    # Drop any DHCP request not carrying the `known` tag we set on
    # static hosts. This is the MAC filter that keeps the rig
    # from accidentally serving strangers if a real-LAN packet
    # somehow reached the bridge.
    dhcp-ignore = "tag:!known";
  };
in
{
  config = lib.mkIf (config.pxe-infra.enable && cfg.enable) {
    services.dnsmasq = {
      enable = true;
      # Don't append 127.0.0.1 to resolv.conf — we are not a DNS
      # resolver.
      resolveLocalQueries = false;
      settings = filtered;
    };
  };
}
