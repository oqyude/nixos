#!/usr/bin/env python3
"""Import-graph integrity check for the nixos flake.

Fails when a .nix file references another .nix file or directory that does
not exist. Two shapes are checked, because both are load-bearing:

  1. import-list entries — a line whose only content (after an optional `#`)
     is a relative path. This is the dominant style in this repo, and it also
     covers commented-out imports, which still mislead the next reader when
     the file they name has been deleted.
  2. `import ../foo` expressions, and single-line `imports = [ ./a ./b ]`.

Deliberately conservative: targets containing a Nix interpolation (`${...}`)
are skipped because they cannot be resolved statically, and paths that appear
inside prose or shell-script bodies are not matched at all.

Usage:  python3 .ci/tests/import-graph.py [repo-root]
Exit:   0 = every import reference resolves, 1 = at least one dangling one.
"""

from __future__ import annotations

import os
import re
import sys

# A line that is nothing but an (optionally commented) relative path.
PURE_PATH = re.compile(
    r"""^[ \t]*\#?[ \t]*((?:\.\.?/)[A-Za-z0-9_./+-]*[A-Za-z0-9_+-])[ \t]*(?:\#.*)?$"""
)
# `import ../foo` / `import ./foo.nix`
IMPORT_EXPR = re.compile(r"""\bimport[ \t]+((?:\.\.?/)[A-Za-z0-9_./+-]*[A-Za-z0-9_+-])""")
# single-line `imports = [ ./a ./b ]`
INLINE_LIST = re.compile(r"""\bimports[ \t]*=[ \t]*\[([^\]]*)\]""")
INLINE_PATH = re.compile(r"""(?:\.\.?/)[A-Za-z0-9_./+-]*[A-Za-z0-9_+-]""")

SKIP_DIRS = {".git", "archive", ".temp", ".omo", ".metaagent-director", "result"}


def nix_files(root: str) -> list[str]:
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(
            d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")
        )
        for name in filenames:
            if name.endswith(".nix"):
                out.append(os.path.join(dirpath, name))
    return sorted(out)


def references(path: str):
    """(line number, target) for every statically resolvable import target."""
    found = []
    with open(path, encoding="utf-8", errors="ignore") as fh:
        for lineno, line in enumerate(fh, 1):
            if "${" in line:
                continue  # dynamic import, not resolvable statically

            m = PURE_PATH.match(line)
            if m:
                found.append((lineno, m.group(1)))
                continue

            for m in IMPORT_EXPR.finditer(line):
                found.append((lineno, m.group(1)))

            m = INLINE_LIST.search(line)
            if m:
                for p in INLINE_PATH.finditer(m.group(1)):
                    found.append((lineno, p.group(0)))
    return found


def resolves(base_file: str, target: str) -> bool:
    cand = os.path.normpath(os.path.join(os.path.dirname(base_file), target))
    if os.path.exists(cand):
        return True
    if not cand.endswith(".nix"):
        # a directory reference may mean `<dir>/default.nix` or `<name>.nix`
        if os.path.exists(os.path.join(cand, "default.nix")):
            return True
        if os.path.exists(cand + ".nix"):
            return True
    return False


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    files = nix_files(root)
    dangling = []
    total = 0
    for path in files:
        for lineno, target in references(path):
            total += 1
            if not resolves(path, target):
                dangling.append((os.path.relpath(path, root), lineno, target))

    if not dangling:
        print(f"import-graph: OK ({len(files)} .nix files, {total} import references resolve)")
        return 0

    print("import-graph: DANGLING IMPORTS", file=sys.stderr)
    for rel, lineno, target in dangling:
        print(f"  {rel}:{lineno} -> {target}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
