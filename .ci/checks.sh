#!/usr/bin/env bash
# Pre-commit + CI checks for the nixos flake.
# Runs the most useful invariants from analysis-report.md §5.
#
# Usage:
#   .ci/checks.sh                # run all
#   .ci/checks.sh --no-build     # skip nix flake check (faster, no network)
#
# Exit codes:
#   0 — all checks passed
#   1 — at least one check failed (stderr has details)
#
# Checks implemented:
#   #2  nix flake check (all outputs evaluate)
#   #7  secrets/ files match .sops.yaml path_regex
#   #1  no `:latest` in container images (with R1.5 whitelist: 3x-ui is frozen on :latest)
#
# Not yet implemented (candidates from analysis-report.md §5):
#   #3  coredns domains ↔ nginx vhosts bidirectional match
#   #4  mkServiceStorage consumers have existing External dir
#   #5  last nftables chain rule is explicit (drop/reject/policy)
#   #6  listen.addr is interface, not network (e.g. 0.0.0.0 is OK, 192.168.0.0/24 is not)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

LATEST_ALLOWLIST=(
  # R1.5: 3x-ui panel frozen on :latest; Xray version is panel state (R1.8)
  "ghcr.io/mhsanaei/3x-ui:latest"
  # tape-rotation: data on External (storage-guarded); manual updates
  "docker.io/elizaroveugene/taperotation-backend:latest"
  "docker.io/elizaroveugene/taperotation-frontend:latest"
)

SKIP_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --no-build) SKIP_BUILD=true ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

PASS=0
FAIL=0
report() {
  if [ "$1" -eq 0 ]; then
    echo "  PASS: $2"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $2" >&2
    FAIL=$((FAIL + 1))
  fi
}

check_nix_flake_check() {
  if [ "$SKIP_BUILD" = true ]; then
    echo "SKIP: nix flake check (--no-build)"
    return 0
  fi
  if ! command -v nix >/dev/null 2>&1; then
    echo "SKIP: nix not in PATH"
    return 0
  fi
  echo "Check #2: nix flake check ..."
  if nix --extra-experimental-features "nix-command flakes" flake check 2>&1 | tail -50; then
    report 0 "nix flake check"
  else
    report 1 "nix flake check"
  fi
}

check_sops_path_regex() {
  echo "Check #7: secrets/ files match .sops.yaml path_regex ..."
  local regex
  regex=$(awk -F'path_regex:[[:space:]]*' '/path_regex:/ {print $2; exit}' .sops.yaml)
  if [ -z "${regex:-}" ]; then
    echo "  SKIP: no path_regex found in .sops.yaml"
    return 0
  fi
  local mismatches=()
  while IFS= read -r -d '' f; do
    if ! printf '%s\n' "$f" | grep -Eqx "${regex}"; then
      mismatches+=("$f")
    fi
  done < <(find secrets -type f -print0 2>/dev/null)
  if [ "${#mismatches[@]}" -eq 0 ]; then
    report 0 "sops path_regex ($regex)"
  else
    echo "  Files NOT matching $regex:" >&2
    printf '    %s\n' "${mismatches[@]}" >&2
    report 1 "sops path_regex ($regex)"
  fi
}

check_no_latest_images() {
  echo "Check #1: no :latest in container images (whitelist allowed) ..."
  local latest_lines
  latest_lines=$(grep -rn --include='*.nix' -E 'image\s*=\s*"[^"]+:latest"' modules/ 2>/dev/null || true)
  if [ -z "$latest_lines" ]; then
    report 0 "no :latest images"
    return 0
  fi
  local latest_images
  latest_images=$(printf '%s\n' "$latest_lines" | sed -E 's/.*image\s*=\s*"([^"]+)".*/\1/')
  local violations=()
  while IFS= read -r img; do
    [ -z "$img" ] && continue
    local allowed=false
    for w in "${LATEST_ALLOWLIST[@]}"; do
      if [ "$img" = "$w" ]; then
        allowed=true
        break
      fi
    done
    if [ "$allowed" = false ]; then
      violations+=("$img")
    fi
  done <<< "$latest_images"
  if [ "${#violations[@]}" -eq 0 ]; then
    report 0 "no :latest images (whitelist honoured)"
  else
    echo "  Images using :latest (not in whitelist):" >&2
    printf '    %s\n' "${violations[@]}" >&2
    echo "  Add to LATEST_ALLOWLIST in .ci/checks.sh if intentional." >&2
    report 1 "no :latest images"
  fi
}

echo "=== nixos flake checks ==="
check_nix_flake_check
check_sops_path_regex
check_no_latest_images
echo "==="
echo "PASS: $PASS    FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
