# pxe-infra/bridge — bring up the private Linux bridge the PXE
# VM attaches to.
#
# Why a systemd oneshot instead of systemd.networkd:
#   rydiwo (and other desktop-class hosts in this flake) run
#   NetworkManager (modules/desktop/default.nix), not systemd-
#   networkd. We still want the bridge up at boot, regardless of
#   LAN connectivity, so we drive the interface ourselves with
#   the iproute2 `ip` command.
#
# Why NetworkManager.unmanaged:
#   If NM were allowed to touch the bridge, it might try to
#   reconfigure it (DHCP the bridge, replace the static IP we
#   just set, or remove it entirely). Marking it unmanaged keeps
#   NM out of our hair.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.pxe-infra.enable {
    # NM must leave the bridge alone — we set it up ourselves.
    networking.networkmanager.unmanaged = [ config.pxe-infra.bridge.name ];

    # Order: bridge must be up before dnsmasq tries to bind to it.
    systemd.services.pxe-infra-bridge = {
      description = "pxe-infra: bring up ${config.pxe-infra.bridge.name} bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      before = [ "dnsmasq.service" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail

        # Idempotent bridge creation.
        if ! ip link show dev ${config.pxe-infra.bridge.name} >/dev/null 2>&1; then
          ip link add name ${config.pxe-infra.bridge.name} type bridge \
            forward_delay 0 stp 0
        fi

        # Idempotent address assignment. Only rewrite the address
        # if it isn't already what we expect — preserves state in
        # case NM did something unexpected before this service ran.
        if ! ip -j addr show dev ${config.pxe-infra.bridge.name} \
            | grep -q '"${config.pxe-infra.bridge.address}"'; then
          ip addr flush dev ${config.pxe-infra.bridge.name} || true
          ip addr add ${config.pxe-infra.bridge.address}/${toString config.pxe-infra.bridge.prefixLength} \
            dev ${config.pxe-infra.bridge.name}
        fi

        # Always make sure the link is up.
        ip link set ${config.pxe-infra.bridge.name} up
      '';
    };
  };
}
