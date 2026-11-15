#!/usr/bin/env python3
"""CoreDNS zone ↔ nginx vhost consistency check.

The repo serves the `zeroq.su` zone from CoreDNS (`modules/server/coredns.nix`)
and terminates the matching vhosts in nginx (`modules/server/nginx.nix`,
`modules/vds/nginx.nix`). Both lists are maintained by hand, so they drift:
a service gets removed from nginx while its DNS record stays behind, and the
name keeps resolving to a vhost that answers 502 (or nothing).

This check finds records that point at a vhost which no longer exists.

Policy
------
* A record in the `zeroq.su` zone with no vhost is a **gap**.
* Gaps that are already known are listed in `.ci/tests/known-domain-gaps.txt`
  (one name per line). A known gap is reported as a warning; a NEW gap fails
  the check. That way the check never blocks a pipeline on pre-existing debt,
  but any future removal of a vhost without touching DNS is caught.
* `home.arpa` is a LAN-only zone: those names intentionally have no public
  vhost, so they are reported as information, not as gaps.
* A vhost without a local DNS record is normal — public domains resolve
  through public DNS and wildcard records cover the `*.opencodes.zeroq.su`
  subdomains. Reported as information only.

Usage:  python3 .ci/tests/check-domains.py [repo-root]
Exit:   0 = no new gaps, 1 = at least one new gap.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

COREDNS = Path("modules/server/coredns.nix")
NGINX_FILES = [
    Path("modules/server/nginx.nix"),
    Path("modules/vds/nginx.nix"),
]
KNOWN_GAPS = Path(".ci/tests/known-domain-gaps.txt")

ZONE_RE = re.compile(r"^\s*([\w.-]+):\d+\s*\{")
# The address is either a literal IP or an interpolation from the fleet
# registry (`${xlib.net.hosts.sapphira.lan}`) — both are one token followed
# by the record name.
RECORD_RE = re.compile(r"^\s*(?:\$\{[^}]+\}|\d+\.\d+\.\d+\.\d+)\s+([\w.-]+)\s*$")
DOMAIN_LITERAL_RE = re.compile(r'"([a-z0-9][a-z0-9.-]*\.(?:zeroq\.su|home\.arpa))"')


def code_lines(text: str) -> list[str]:
    """Drop full-line comments. Inline comments are kept on purpose: a domain
    inside a comment is a claim about the world, but a commented-out vhost
    block is code the reader will mistake for live code."""
    return [line for line in text.split("\n") if not line.strip().startswith("#")]


def parse_zone(text: str) -> dict[str, list[str]]:
    """zone name -> list of record names."""
    zones: dict[str, list[str]] = {}
    current = None
    for line in code_lines(text):
        zone = ZONE_RE.match(line)
        if zone:
            current = zone.group(1)
            zones.setdefault(current, [])
            continue
        if current is None:
            continue
        record = RECORD_RE.match(line)
        if record:
            zones[current].append(record.group(1))
    return zones


def parse_vhosts(paths: list[Path], root: Path) -> set[str]:
    names: set[str] = set()
    for path in paths:
        full = root / path
        if not full.exists():
            continue
        for line in code_lines(full.read_text(encoding="utf-8", errors="ignore")):
            for match in DOMAIN_LITERAL_RE.finditer(line):
                names.add(match.group(1))
    return names


def known_gaps(root: Path) -> set[str]:
    full = root / KNOWN_GAPS
    if not full.exists():
        return set()
    out = set()
    for line in full.read_text(encoding="utf-8", errors="ignore").split("\n"):
        line = line.split("#", 1)[0].strip()
        if line:
            out.add(line)
    return out


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()

    coredns = root / COREDNS
    if not coredns.exists():
        print(f"  MISSING: {COREDNS.relative_to(root)}")
        return 1

    zones = parse_zone(coredns.read_text(encoding="utf-8", errors="ignore"))
    vhosts = parse_vhosts(NGINX_FILES, root)
    allowed = known_gaps(root)

    public_zone = "zeroq.su"
    records = set(zones.get(public_zone, []))
    lan_records = set(zones.get("home.arpa", []))

    gaps = sorted(records - vhosts)
    new_gaps = [name for name in gaps if name not in allowed]
    stale_allowed = [name for name in gaps if name in allowed]

    print(f"domains: {len(records)} record(s) in {public_zone}, {len(vhosts)} vhost(s) known")

    if stale_allowed:
        print(f"  NOTE: {len(stale_allowed)} known gap(s) (recorded in {KNOWN_GAPS}):")
        for name in stale_allowed:
            print(f"    - {name}")
    if lan_records:
        print(f"  INFO: {len(lan_records)} LAN-only record(s) in home.arpa have no public vhost (expected)")
    vhost_only = sorted(vhosts - records - lan_records)
    if vhost_only:
        print(f"  INFO: {len(vhost_only)} vhost(s) without a local DNS record (public DNS / wildcard):")
        for name in vhost_only:
            print(f"    - {name}")

    if new_gaps:
        print(f"domains: NEW GAPS — {len(new_gaps)} DNS record(s) without a vhost", file=sys.stderr)
        for name in new_gaps:
            print(f"  {name}", file=sys.stderr)
        print(
            "  Either restore the vhost, remove the DNS record from "
            f"{COREDNS}, or add the name to {KNOWN_GAPS}",
            file=sys.stderr,
        )
        return 1

    print("domains: OK (no new gaps)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
