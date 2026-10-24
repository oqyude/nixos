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
#   #1  no `:latest` in container images (whitelist: tape-rotation only;
#       3x-ui is pinned to v3.10.2 since 2026-10-20, R1.5)
#   #8  every import reference resolves (no dangling imports) — added 2026-10-24
#   #9  .agent JSON artefacts validate against their schemas — added 2026-10-25
#
# Not yet implemented (candidates from analysis-report.md §5):
#   #3  coredns domains ↔ nginx vhosts bidirectional match
#   #4  mkStorageGuard consumers have an existing External dir
#       (lib/xlib/helpers.nix — note the helper is mkStorageGuard, not
#       mkServiceStorage; the two names referred to the same idea historically.
#       The helper now returns a `unitConfig` fragment, and vds hosts are
#       excluded: otreca has no External, its 3x-ui data lives on the root fs)
#   #5  nftables policy (T3 CLOSED 2026-10-25: no check needed — the generated
#       `inet nixos-fw` chain already has `policy drop`; the hand-written
#       `inet filter` chain is policy accept on purpose and must NOT get a drop,
#       because a drop in any base chain is final and would blackhole the VDS)
#   #6  listen.addr is interface, not network (e.g. 0.0.0.0 is OK, 192.168.0.0/24 is not)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

LATEST_ALLOWLIST=(
  # tape-rotation: data on External (storage-guarded); manual updates.
  # The 3x-ui panel used to be whitelisted here as "frozen on :latest".
  # It is pinned to ghcr.io/mhsanaei/3x-ui:v3.10.2 since 2026-10-20 (R1.5),
  # so a `:latest` for it must now fail this check instead of being allowed.
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
  echo "Check #7: sops-encrypted files match .sops.yaml path_regex ..."
  local regex
  regex=$(awk -F'path_regex:[[:space:]]*' '/path_regex:/ {print $2; exit}' .sops.yaml)
  if [ -z "${regex:-}" ]; then
    echo "  SKIP: no path_regex found in .sops.yaml"
    return 0
  fi
  local mismatches=() unanchored=() f
  # Every file under any `secrets/` directory is a candidate for the sops
  # creation rule — not only the ones in the top-level `secrets/`. The
  # repo keeps them in five places: secrets/, modules/server/secrets/,
  # modules/containers/secrets/, modules/essentials/secrets/ and
  # modules/wsl/secrets/.
  #
  # Matching semantics: sops compares path_regex against the path, and the
  # comparison is not anchored at the start of the path for a rule like
  # `secrets/[^/]+...`. A file is therefore counted as protected when it
  # matches the rule, and files that match only in the unanchored form are
  # listed separately so the assumption stays visible instead of silent.
  while IFS= read -r f; do
    f="${f#./}"
    if ! printf '%s\n' "$f" | grep -Eq "${regex}"; then
      mismatches+=("$f")
    elif ! printf '%s\n' "$f" | grep -Eq "^${regex}"; then
      unanchored+=("$f")
    fi
  done < <(find . -type f -path '*/secrets/*' -not -path './.git/*' 2>/dev/null | sort)
  if [ "${#unanchored[@]}" -gt 0 ]; then
    echo "  NOTE: ${#unanchored[@]} file(s) match the rule only when it is not anchored"
    echo "        at the start of the path (sops behaviour for nested secrets/):"
    printf '          %s\n' "${unanchored[@]}"
  fi
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

check_import_graph() {
  echo "Check #8: every import reference resolves (no dangling imports) ..."
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not in PATH"
    return 0
  fi
  if python3 .ci/tests/import-graph.py . ; then
    report 0 "import graph"
  else
    report 1 "import graph"
  fi
}

check_metadata_schemas() {
  echo "Check #9: .agent JSON artefacts validate against their schemas ..."
  if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not in PATH"
    return 0
  fi
  if python3 .ci/tests/validate-metadata.py . ; then
    report 0 "metadata schemas"
  else
    report 1 "metadata schemas"
  fi
}

echo "=== nixos flake checks ==="
check_nix_flake_check
check_sops_path_regex
check_no_latest_images
check_import_graph
check_metadata_schemas
echo "==="
echo "PASS: $PASS    FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
