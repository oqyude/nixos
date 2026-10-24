#!/usr/bin/env python3
"""Validate the MetaAgent JSON artefacts against their project schemas.

No third-party dependency: the subset of JSON Schema used by the schemas in
.agent/src/TEMPLATES/schemas/ is implemented here (type, enum, required,
properties, additionalProperties, items, pattern, basic format).  Keeping the
validator dependency-free matters because .ci/checks.sh runs both locally and
in the Gitea workflow, where only python3 is guaranteed.

Exit code 0 when every artefact validates, 1 otherwise.  Every mismatch is
printed with its JSON path so the fix is obvious.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
SCHEMAS = ROOT / ".agent/src/TEMPLATES/schemas"

TARGETS = [
    (ROOT / ".agent/tasks/manifest.json", SCHEMAS / "task-manifest-schema.json"),
    (ROOT / ".agent/checkpoints.json", SCHEMAS / "checkpoints-schema.json"),
    (ROOT / ".agent/decisions/index.json", SCHEMAS / "decisions-index-schema.json"),
    (ROOT / ".agent/src/TEMPLATES/request.json", SCHEMAS / "request-schema.json"),
]

TYPE_MAP = {
    "object": dict,
    "array": list,
    "string": str,
    "integer": int,
    "number": (int, float),
    "boolean": bool,
    "null": type(None),
}


def is_type(value, name: str) -> bool:
    if name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if name == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    expected = TYPE_MAP.get(name)
    return expected is not None and isinstance(value, expected)


def validate(value, schema, path, errors):
    if not isinstance(schema, dict):
        return

    declared = schema.get("type")
    if declared is not None:
        names = declared if isinstance(declared, list) else [declared]
        if not any(is_type(value, name) for name in names):
            errors.append(f"{path}: expected type {'/'.join(names)}, got {type(value).__name__}")
            return

    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: {value!r} is not one of {schema['enum']}")

    if isinstance(value, str):
        pattern = schema.get("pattern")
        if pattern and not re.search(pattern, value):
            errors.append(f"{path}: {value!r} does not match /{pattern}/")

    if isinstance(value, dict):
        props = schema.get("properties", {})
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{path}: missing required property {key!r}")
        additional = schema.get("additionalProperties", True)
        for key, item in value.items():
            child = f"{path}.{key}"
            if key in props:
                validate(item, props[key], child, errors)
            elif additional is False:
                errors.append(f"{path}: unexpected property {key!r}")
            elif isinstance(additional, dict):
                validate(item, additional, child, errors)

    if isinstance(value, list) and isinstance(schema.get("items"), dict):
        for index, item in enumerate(value):
            validate(item, schema["items"], f"{path}[{index}]", errors)


def main() -> int:
    failed = 0
    for artefact, schema_path in TARGETS:
        if not artefact.exists():
            print(f"  MISSING: {artefact.relative_to(ROOT)}")
            failed += 1
            continue
        if not schema_path.exists():
            print(f"  MISSING SCHEMA: {schema_path.relative_to(ROOT)}")
            failed += 1
            continue
        try:
            instance = json.loads(artefact.read_text(encoding="utf-8"))
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            print(f"  INVALID JSON: {artefact.relative_to(ROOT)}: {error}")
            failed += 1
            continue
        errors: list[str] = []
        validate(instance, schema, artefact.relative_to(ROOT).as_posix(), errors)
        if errors:
            failed += 1
            print(f"  {artefact.relative_to(ROOT)}: {len(errors)} violation(s)")
            for message in errors[:25]:
                print(f"    - {message}")
            if len(errors) > 25:
                print(f"    ... and {len(errors) - 25} more")
        else:
            print(f"  ok: {artefact.relative_to(ROOT)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
