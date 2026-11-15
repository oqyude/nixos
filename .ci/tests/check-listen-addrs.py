#!/usr/bin/env python3
"""`listen.addr` must name an interface, not a network.

nginx's `listen <addr>:<port>` takes the address of an interface. A network
with a prefix length (`192.168.1.0/24`) or a multicast/broadcast address is
not an interface address: nginx either refuses to start or, worse, binds
nothing while the config looks fine. The same value in `allowedTCPPorts` /
`allowedUDPPorts` is a different thing entirely (a port, not an address), so
only `addr =` is inspected.

Note what is deliberately NOT flagged: an address that merely *looks* like a
network prefix (`100.64.0.0` is the Tailscale address of sapphira, not the
`100.64.0.0/10` network). Only an explicit prefix length is an error.

Usage:  python3 .ci/tests/check-listen-addrs.py [repo-root]
Exit:   0 = every `addr` is an interface address, 1 otherwise.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

SKIP_DIRS = {".git", "archive", ".temp", ".omo", ".metaagent-director", "result"}

ADDR_RE = re.compile(r'\baddr\s*=\s*"([^"]+)"')
IPV4_RE = re.compile(r"^\d{1,3}(\.\d{1,3}){3}$")


def nix_files(root: Path) -> list[Path]:
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS and not d.startswith("."))
        for name in filenames:
            if name.endswith(".nix"):
                out.append(Path(dirpath) / name)
    return sorted(out)


def classify(addr: str) -> str | None:
    """Return an error message, or None when the address is fine."""
    if "/" in addr:
        return "network prefix — listen takes an interface address, not a network"
    host = addr
    if host.startswith("["):
        host = host.split("]", 1)[0].lstrip("[")
    elif host.count(":") == 1:
        host = host.split(":", 1)[0]
    if IPV4_RE.match(host):
        octets = [int(part) for part in host.split(".")]
        if octets[0] >= 224 and octets[0] <= 239:
            return "multicast address"
        if octets == [255, 255, 255, 255]:
            return "broadcast address"
        # `0.0.0.0` is explicitly allowed: nginx treats it as "every
        # interface", which is a legitimate listen target (see the rule in
        # .ci/checks.sh: "0.0.0.0 is OK, 192.168.0.0/24 is not").
    return None


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    problems = []
    for path in nix_files(root):
        rel = path.relative_to(root)
        for lineno, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").split("\n"), 1):
            if line.lstrip().startswith("#"):
                continue
            for match in ADDR_RE.finditer(line):
                addr = match.group(1)
                problem = classify(addr)
                if problem:
                    problems.append((rel.as_posix(), lineno, addr, problem))

    if not problems:
        print("listen-addrs: OK (every addr is an interface address)")
        return 0

    print("listen-addrs: INVALID listen.addr", file=sys.stderr)
    for rel, lineno, addr, problem in problems:
        print(f"  {rel}:{lineno} addr = \"{addr}\" — {problem}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
