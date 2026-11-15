#!/usr/bin/env bash
# Runtime drift: what Nix declares vs what the host actually runs.
#
# The repo knows this failure mode well (AGENTS.md invariant 8, ADR-0003):
# a Nix change is a *declaration*. It changes the running system only after
# `nixos-rebuild switch` — and for containers it changes nothing at all until
# the container is recreated. A config that is correct on disk and wrong in
# production produces no error anywhere: the panel answers, the port is wrong,
# the logs are silent.
#
# This script closes that gap for a live host. It compares three pairs:
#
#   1. nginx    — the rendered config (/etc/nginx/nginx.conf) vs the config
#                 nginx actually loaded (`nginx -T`). A vhost present in the
#                 file but absent from the running config means the rebuild
#                 happened and the reload did not.
#   2. podman   — the ports declared in the rendered systemd unit vs the ports
#                 the running container actually publishes. This is the case
#                 that never recovers on its own (invariant 8).
#   3. systemd  — every unit that the repo guards with
#                 `ConditionPathIsMountPoint` must actually carry that
#                 condition at runtime. A unit without it is a guard that
#                 silently does nothing (ADR-0004: the attribute name must
#                 match the real unit, or a phantom without ExecStart wins).
#
# Usage (on the host, as root):
#   bash .ci/verify/runtime-drift.sh [--nginx] [--podman] [--systemd]
#
# Exit code: 0 when nothing drifted, 1 when at least one drift was found.
#
# This script is NOT part of CI: it needs a live host with the services
# running. Run it after a rebuild, or from cron on the production hosts.
set -uo pipefail

NGINX_CONF="${NGINX_CONF:-/etc/nginx/nginx.conf}"
GUARDED_UNITS=(
  samba-smbd
  phpfpm-nextcloud
  immich-server
  podman-3xui_app
  podman-taperotation-backend
  podman-taperotation-frontend
)

DO_NGINX=0
DO_PODMAN=0
DO_SYSTEMD=0
if [ "$#" -eq 0 ]; then
  DO_NGINX=1
  DO_PODMAN=1
  DO_SYSTEMD=1
else
  for arg in "$@"; do
    case "$arg" in
      --nginx) DO_NGINX=1 ;;
      --podman) DO_PODMAN=1 ;;
      --systemd) DO_SYSTEMD=1 ;;
      *)
        echo "Unknown arg: $arg" >&2
        exit 2
        ;;
    esac
  done
fi

DRIFT=0

# --- nginx: rendered file vs loaded config ---------------------------------
if [ "$DO_NGINX" -eq 1 ]; then
  echo "=== nginx: rendered config vs loaded config ==="
  if ! command -v nginx >/dev/null 2>&1; then
    echo "  SKIP: nginx not in PATH"
  elif [ ! -f "$NGINX_CONF" ]; then
    echo "  SKIP: $NGINX_CONF not found"
  else
    rendered=$(mktemp)
    loaded=$(mktemp)
    grep -hoE '^[[:space:]]*server_name[[:space:]]+[^;]+;' "$NGINX_CONF" |
      sed -E 's/.*server_name[[:space:]]+//; s/;//' | tr ' ' '\n' | sort -u >"$rendered"
    nginx -T 2>/dev/null |
      grep -hoE '^[[:space:]]*server_name[[:space:]]+[^;]+;' |
      sed -E 's/.*server_name[[:space:]]+//; s/;//' | tr ' ' '\n' | sort -u >"$loaded"
    if diff -u "$rendered" "$loaded" >/dev/null 2>&1; then
      echo "  OK: nginx serves the same server_name set as the rendered config"
    else
      echo "  DRIFT: nginx has NOT reloaded the current config" >&2
      diff -u "$rendered" "$loaded" | sed 's/^/    /' >&2
      DRIFT=1
    fi
    rm -f "$rendered" "$loaded"
  fi
  echo
fi

# --- podman: declared ports vs published ports -----------------------------
if [ "$DO_PODMAN" -eq 1 ]; then
  echo "=== podman: declared ports vs published ports ==="
  if ! command -v podman >/dev/null 2>&1; then
    echo "  SKIP: podman not in PATH"
  else
    for unit in $(systemctl list-units --type=service --all --no-legend 2>/dev/null |
      awk '$1 ~ /^podman-/ {print $1}'); do
      unit_file="/etc/systemd/system/${unit}.service"
      [ -f "$unit_file" ] || continue
      container=$(sed -nE 's/.*--name[= ]"?([^" ]+)"?.*/\1/p' "$unit_file" | head -1)
      [ -n "$container" ] || continue
      if ! podman inspect "$container" >/dev/null 2>&1; then
        echo "  DRIFT: ${unit}: container '${container}' does not exist (never created?)" >&2
        DRIFT=1
        continue
      fi
      declared=$(sed -nE 's/.*(-p|--publish)[= ]"?([^" ]+)"?.*/\2/p' "$unit_file" |
        tr ',' '\n' | sed 's/^[[:space:]]*//' | sort -u)
      published=$(podman inspect "$container" --format '{{json .NetworkSettings.Ports}}' 2>/dev/null)
      for entry in $declared; do
        host_port="${entry%%:*}"
        if ! printf '%s' "$published" | grep -q "\"${host_port}/tcp\""; then
          echo "  DRIFT: ${unit}: declares -p ${entry} but the running container does not publish ${host_port}/tcp" >&2
          echo "         declared:  ${declared}" >&2
          echo "         published: ${published}" >&2
          echo "         fix: podman rm ${container} && systemctl restart ${unit}" >&2
          DRIFT=1
        fi
      done
    done
    [ "$DRIFT" -eq 0 ] && echo "  OK: every container publishes the ports its unit declares"
  fi
  echo
fi

# --- systemd: storage guard actually landed in the unit ---------------------
if [ "$DO_SYSTEMD" -eq 1 ]; then
  echo "=== systemd: storage guard present in the unit ==="
  for unit in "${GUARDED_UNITS[@]}"; do
    if ! systemctl show "$unit" >/dev/null 2>&1; then
      echo "  SKIP: ${unit} is not installed on this host"
      continue
    fi
    condition=$(systemctl show "$unit" -p ConditionPathIsMountPoint --value 2>/dev/null)
    if [ -z "$condition" ]; then
      echo "  DRIFT: ${unit} carries no ConditionPathIsMountPoint — the storage guard is dead" >&2
      DRIFT=1
    else
      echo "  OK: ${unit} guarded by ${condition}"
    fi
  done
  echo
fi

if [ "$DRIFT" -ne 0 ]; then
  echo "runtime-drift: DRIFT DETECTED" >&2
  exit 1
fi
echo "runtime-drift: OK (declaration and runtime agree)"
