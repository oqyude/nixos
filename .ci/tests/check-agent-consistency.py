#!/usr/bin/env python3
"""Consistency between the three places the repo talks about tasks.

The repo tracks tasks in three places and they drift:

  * `.agent/tasks/manifest.json` — the machine-readable source of truth
    (status per task id).
  * `.agent/tasks/manifest.md`   — the human-readable registry of the T38+
    series, with a status column.
  * `AGENTS.md`                  — the entry point for the next agent, with a
    one-line summary of which tasks are still open.

plus `.agent/decisions/index.json`, which indexes the ADR files on disk.

Nothing enforces agreement, so a task can be "done" in one file and "pending"
in another — and the next agent reads whichever it happens to open. This check
compares them and fails on a contradiction.

Rules
-----
1. AGENTS.md's "Открытые задачи" line must list exactly the tasks that
   `manifest.json` does not mark completed (pending + in_progress).
2. For every task present in both `manifest.json` and the `manifest.md`
   table: "done" in one and not-done in the other is a contradiction.
   A task in `manifest.json` but missing from the `manifest.md` table is
   reported as drift (the md is a registry, not a mirror — but a task that
   nobody can find is a task that will be re-discovered by hand).
3. Every ADR in `decisions/index.json` must have its file on disk, and every
   ADR file on disk must be indexed.

Usage:  python3 .ci/tests/check-agent-consistency.py [repo-root]
Exit:   0 = consistent, 1 = at least one contradiction.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

MANIFEST_JSON = Path(".agent/tasks/manifest.json")
MANIFEST_MD = Path(".agent/tasks/manifest.md")
AGENTS_MD = Path("AGENTS.md")
DECISIONS_INDEX = Path(".agent/decisions/index.json")
DECISIONS_DIR = Path(".agent/decisions")

DONE_STATES = {"completed", "done", "closed"}
ID_RE = re.compile(r"T(\d+)")


def expand_ids(text: str) -> set[int]:
    """T10, T28-T31, T49–T56 -> {10, 28, 29, 30, 31, 49, ...}."""
    found: set[int] = set()
    for match in re.finditer(r"T(\d+)\s*(?:[-–—]\s*T?(\d+))?", text):
        start = int(match.group(1))
        end = int(match.group(2)) if match.group(2) else start
        if end < start:
            start, end = end, start
        found.update(range(start, end + 1))
    return found


def md_table_statuses(text: str) -> dict[int, str]:
    """Task id -> raw status cell from the markdown table."""
    statuses: dict[int, str] = {}
    for line in text.split("\n"):
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) < 5:
            continue
        match = re.fullmatch(r"\*?\*?T(\d+)\*?\*?", cells[0])
        if not match:
            continue
        statuses[int(match.group(1))] = cells[4]
    return statuses


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    problems: list[str] = []

    manifest_path = root / MANIFEST_JSON
    if not manifest_path.exists():
        print(f"  MISSING: {MANIFEST_JSON}")
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    tasks = {int(ID_RE.fullmatch(t["id"]).group(1)): t for t in manifest["tasks"] if ID_RE.fullmatch(t["id"])}
    open_ids = {tid for tid, t in tasks.items() if t.get("status") not in DONE_STATES}

    # 1. AGENTS.md summary line.
    agents_path = root / AGENTS_MD
    if agents_path.exists():
        agents_text = agents_path.read_text(encoding="utf-8")
        summary = None
        agents_lines = agents_text.split("\n")
        for index, line in enumerate(agents_lines):
            if "Открытые задачи" in line:
                # The summary may wrap over several lines — take the whole
                # paragraph, otherwise the wrapped task ids are invisible to
                # the comparison.
                paragraph = [line]
                for follow_up in agents_lines[index + 1 :]:
                    if not follow_up.strip():
                        break
                    paragraph.append(follow_up)
                summary = "\n".join(paragraph)
                break
        if summary is None:
            problems.append("AGENTS.md: no 'Открытые задачи' line — the task summary is missing")
        else:
            listed = expand_ids(summary)
            missing = sorted(open_ids - listed)
            extra = sorted(tid for tid in listed - open_ids if tid in tasks)
            unknown = sorted(tid for tid in listed - set(tasks))
            if missing:
                problems.append(
                    f"AGENTS.md: open task(s) not mentioned in the summary line: "
                    + ", ".join(f"T{tid}" for tid in missing)
                )
            if extra:
                problems.append(
                    f"AGENTS.md: summary line lists task(s) that are already completed: "
                    + ", ".join(f"T{tid}" for tid in extra)
                )
            if unknown:
                problems.append(
                    "AGENTS.md: summary line lists unknown task(s): "
                    + ", ".join(f"T{tid}" for tid in unknown)
                )
    else:
        problems.append(f"MISSING: {AGENTS_MD}")

    # 2. manifest.md table vs manifest.json.
    md_path = root / MANIFEST_MD
    if md_path.exists():
        md_statuses = md_table_statuses(md_path.read_text(encoding="utf-8"))
        for tid, cell in sorted(md_statuses.items()):
            if tid not in tasks:
                problems.append(f"manifest.md: T{tid} is not in manifest.json")
                continue
            md_done = "done" in cell.lower()
            json_done = tasks[tid].get("status") in DONE_STATES
            if md_done != json_done:
                problems.append(
                    f"manifest.md T{tid}: table says '{cell}' but manifest.json says "
                    f"'{tasks[tid].get('status')}'"
                )
        listed_in_md = set(md_statuses)
        missing_in_md = sorted(tid for tid in tasks if tid >= 38 and tid not in listed_in_md)
        if missing_in_md:
            problems.append(
                "manifest.md: task(s) from the T38+ series are not in the table: "
                + ", ".join(f"T{tid}" for tid in missing_in_md)
            )
    else:
        problems.append(f"MISSING: {MANIFEST_MD}")

    # 3. ADR index vs ADR files.
    index_path = root / DECISIONS_INDEX
    if index_path.exists():
        index = json.loads(index_path.read_text(encoding="utf-8"))
        indexed_files = set()
        for decision in index.get("decisions", []):
            rel = decision.get("file")
            if not rel:
                problems.append(f"decisions/index.json: {decision.get('id')} has no file")
                continue
            indexed_files.add(Path(rel).name)
            if not (root / rel).exists():
                problems.append(f"decisions/index.json: {decision.get('id')} points at a missing file {rel}")
        on_disk = {
            p.name
            for p in (root / DECISIONS_DIR).glob("*.md")
            if re.match(r"^\d{4}-", p.name)
        }
        for name in sorted(on_disk - indexed_files):
            problems.append(f"decisions: {name} exists on disk but is not in decisions/index.json")
    else:
        problems.append(f"MISSING: {DECISIONS_INDEX}")

    print(
        f"agent-consistency: {len(tasks)} task(s), {len(open_ids)} open, "
        f"{len(md_statuses) if md_path.exists() else 0} row(s) in the manifest.md table"
    )
    if problems:
        print("agent-consistency: INCONSISTENCIES", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print("agent-consistency: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
