#!/usr/bin/env bash
# Config fingerprint — behavioural snapshot of every host configuration.
#
# Why: a refactor that "does not change behaviour" is a claim, not a fact.
# This script turns the claim into a diff. It evaluates each host config and
# dumps the parts that carry behaviour — systemd unit names, firewall ports,
# nginx vhosts and their upstreams, CoreDNS zone contents, package sets,
# mounts, container images/ports — as JSON. Two revisions can then be
# compared byte for byte.
#
# Deliberately NOT included: secret values. `sops.secrets.*.path` is captured
# (names only), never the decrypted content, so the snapshot is safe to keep
# in a work directory and to diff on a laptop.
#
# Usage:
#   .ci/verify/config-fingerprint.sh [out-dir] [hosts...]
#
#   out-dir   where to write <host>.json (default: ./fingerprint-<utc-ts>)
#   hosts     subset of host names (default: all NixOS configurations)
#
# Example:
#   .ci/verify/config-fingerprint.sh /tmp/before
#   # ... change something ...
#   .ci/verify/config-fingerprint.sh /tmp/after
#   diff -r /tmp/before /tmp/after && echo "no behavioural change"
#
# IMPORTANT — materialise both revisions the same way, or the diff lies.
# Store paths are part of the snapshot, and a store path depends on the
# executable bit of the file it was copied from. A checkout made on Windows
# (/mnt/c, drvfs) reports every file as executable, a `git archive` on Linux
# restores the mode recorded in the git index. Compare a Windows working copy
# against a `git archive` export and `overlays/patch-whitesur-sddm.pl` comes
# out with two different store paths — which changes the `system-path`
# derivation, which changes `XDG_DATA_DIRS` in accounts-daemon.service, which
# changes the `X-Restart-Triggers` files of dbus-broker and polkit. None of
# that is a behavioural change; it is the same bytes in a different wrapper.
#
#   git archive dev   | tar -x -C /tmp/dev
#   git archive agent | tar -x -C /tmp/agent
#   (cd /tmp/dev   && .ci/verify/config-fingerprint.sh /tmp/fp-dev)
#   (cd /tmp/agent && .ci/verify/config-fingerprint.sh /tmp/fp-agent)
#   diff -r /tmp/fp-dev /tmp/fp-agent
#
# Exit code: 0 when every requested host evaluated, 1 otherwise.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="${1:-./fingerprint-$(date -u +%Y%m%dT%H%M%SZ)}"
shift || true

if [ "$#" -gt 0 ]; then
  HOSTS="$*"
else
  # Attribute names of `nixosConfigurations` — `default` included: it is a real
  # configuration (the minimal template), and a change there is a change to the
  # template every new host starts from.
  HOSTS=$(nix --extra-experimental-features "nix-command flakes" eval \
    --raw '.#nixosConfigurations' --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)')
fi

mkdir -p "$OUT_DIR"

# The expression applied to `config`. Kept in one place so the snapshot shape
# cannot drift between hosts.
FINGERPRINT_EXPR='c: let
  # Package sets come in two shapes: `home.packages` is an attribute set
  # (home-manager), `users.users.<u>.packages` is a list (NixOS). Both are
  # normalised to a sorted list of names. A derivation is named by its
  # `name` attribute on purpose: `toString` would yield the store path, which
  # differs between revisions even when the package set is identical.
  pkgNames = v:
    if builtins.isAttrs v then
      builtins.attrNames v
    else
      map (x: if builtins.isAttrs x then (x.name or x.pname or "?") else toString x) v;
in {
  hostname = c.networking.hostName;
  systemdServices = builtins.attrNames c.systemd.services;
  # Unit-level conditions of every service. This is where the storage guard
  # lives (AGENTS.md invariant 2: `ConditionPathIsMountPoint` must land in
  # the [Unit] section) and where a phantom unit would show up
  # (ADR-0004: the attribute name must match the real unit).
  systemdUnitConfig = builtins.mapAttrs (_: s: s.unitConfig or {}) c.systemd.services;
  services = builtins.attrNames c.services;
  sopsSecrets = builtins.attrNames c.sops.secrets;
  firewall = {
    allowedTCPPorts = c.networking.firewall.allowedTCPPorts;
    allowedUDPPorts = c.networking.firewall.allowedUDPPorts;
    interfaces = builtins.mapAttrs (_: v: {
      allowedTCPPorts = v.allowedTCPPorts;
      allowedUDPPorts = v.allowedUDPPorts;
    }) c.networking.firewall.interfaces;
  };
  nginx = builtins.mapAttrs (_: v: {
    listen = v.listen or [];
    forceSSL = v.forceSSL or null;
    enableACME = v.enableACME or null;
    locations = builtins.mapAttrs (_: l: {
      proxyPass = l.proxyPass or null;
      proxyWebsockets = l.proxyWebsockets or null;
      extraConfig = l.extraConfig or null;
    }) v.locations;
  }) c.services.nginx.virtualHosts;
  coredns = c.services.coredns.config;
  users = builtins.mapAttrs (_: u: {
    packages = pkgNames (u.packages or {});
    extraGroups = u.extraGroups or [];
  }) c.users.users;
  homeUsers = builtins.mapAttrs (_: u: {
    packages = pkgNames (u.home.packages or {});
    programs = builtins.attrNames (u.home.programs or {});
    files = builtins.attrNames (u.home.file or {});
    services = builtins.attrNames (u.home.services or {});
    sessionVariables = builtins.attrNames (u.home.sessionVariables or {});
    # systemd user units: ExecStart and Environment are the contract between
    # the unit and the server behind it (ports, CORS, proxy settings).
    systemdUserServices = builtins.mapAttrs (_: s: {
      ExecStart = s.ExecStart or null;
      Environment = s.Environment or null;
      description = s.description or null;
    }) ((u.systemd.user.services or {}) // {});
  }) c.home-manager.users;
  systemPackages = pkgNames c.environment.systemPackages;
  nextcloudSettings = c.services.nextcloud.settings or null;
  samba = {
    enable = c.services.samba.enable;
    workgroup = c.services.samba.workgroup or null;
    domain = c.services.samba.domain or null;
  };
  fileSystems = builtins.mapAttrs (_: v: {
    device = v.device;
    fsType = v.fsType;
    options = v.options or [];
  }) c.fileSystems;
  containers = builtins.mapAttrs (_: v: {
    image = v.image;
    ports = v.ports or [];
    volumes = v.volumes or [];
    environment = if (v.environment or null) == null then [] else if builtins.isAttrs v.environment then builtins.attrNames v.environment else v.environment;
  }) c.virtualisation.oci-containers.containers;
  sessionVariables = builtins.attrNames c.environment.sessionVariables;
  boot = {
    kernel = c.boot.kernelPackages.kernel.version;
  };
}'

FAILED=0
for host in $HOSTS; do
  echo "fingerprint: evaluating ${host} ..."
  if nix --extra-experimental-features "nix-command flakes" eval \
    --json ".#nixosConfigurations.${host}.config" \
    --apply "$FINGERPRINT_EXPR" >"${OUT_DIR}/${host}.json" 2>"${OUT_DIR}/${host}.err"; then
    echo "  ok: ${OUT_DIR}/${host}.json"
  else
    echo "  FAIL: ${host}" >&2
    sed 's/^/    /' "${OUT_DIR}/${host}.err" >&2
    FAILED=1
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo "fingerprint: some hosts failed to evaluate" >&2
  exit 1
fi
echo "fingerprint: written to ${OUT_DIR}"
