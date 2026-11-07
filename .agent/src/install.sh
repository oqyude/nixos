#!/usr/bin/env bash
# MetaAgent — установка кита в целевой проект: это ВЕСЬ INIT, не только копия
# исходников.
#
# Usage: ./install.sh [--check|--update] [target_path]
#
# ЧТО СОЗДАЁТСЯ
# -------------
#   <target>/.agent/src/...                 кит, файл в файл по KIT-MANIFEST.tsv
#   <target>/.agent/checkpoints.json        литерал из PROTOCOLS/00_INIT.md §0.8,
#                                           по TEMPLATES/schemas/checkpoints-schema.json
#   <target>/.agent/rules/project-rules.md  из TEMPLATES/project-rules.md
#   <target>/.agent/decisions/index.json    {"version":"3.0","decisions":[]},
#                                           по TEMPLATES/schemas/decisions-index-schema.json
#   <target>/.temp/  +  строка `.temp/` в <target>/.gitignore
#   <target>/AGENTS.md                      из AGENTS.template.md, {VERSION} подставлен
#
# ДВА РАЗНЫХ ПРАВИЛА, И ЭТО НАМЕРЕННО
# -----------------------------------
#   `.agent/src/`  — копия кита. Перезаписывается ТОЛЬКО с `--update`.
#   Всё остальное — данные проекта: checkpoints, правила, реестр ADR,
#   `.gitignore`, `AGENTS.md`. Пишется ТОЛЬКО если файла нет; не
#   перезаписывается никогда, ни на первом прогоне, ни с `--update`.
#   `--update` — это «обнови кит», а не «снеси моё состояние»: правила и
#   чекпоинты принадлежат проекту, и установщик не знает, что в них важного.
#
# ИДЕМПОТЕНТНОСТЬ: второй прогон не меняет ни одного пути, ни одного размера
# и ни одной mtime (проверяется tests/sh-framework-install-init.sh).
set -euo pipefail

METAAGENT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- helpers ---
red=; grn=; ylw=; blu=; rst=
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    red=$(tput setaf 1); grn=$(tput setaf 2)
    ylw=$(tput setaf 3); blu=$(tput setaf 4)
    rst=$(tput sgr0)
fi
info()  { echo "  ${blu}→${rst} $*"; }
ok()    { echo "  ${grn}✓${rst} $*"; }
skip()  { echo "  ${ylw}−${rst} $*"; }
warn()  { echo "  ${ylw}⚠${rst} $*"; }
fail()  { echo "  ${red}✗${rst} $*"; }
header(){ echo; echo "────────────────────────────────────────"; echo " $*"; echo "────────────────────────────────────────"; }

usage() {
    cat <<EOF
Usage: $0 [--check|--update] [target_path]

Install the MetaAgent kit into <target>/.agent/src/ and finish INIT:
checkpoints.json, rules/project-rules.md, decisions/index.json,
.temp/ + .gitignore, AGENTS.md.

Options:
  --check, -c     Dry-run: check the target and print what INIT would create
  --update, -u    Overwrite existing files in .agent/src/ (the kit copy ONLY —
                  checkpoints, rules, decisions, .gitignore and AGENTS.md are
                  never overwritten, not even with --update)
  --help, -h      Show this help

Examples:
  $0
  $0 /path/to/project
  $0 --check /path/to/project
  $0 --update /path/to/project
EOF
    exit 0
}

# --- arg parsing ---
CHECK=false
UPDATE=false
TARGET_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check|-c)    CHECK=true; shift ;;
        --update|-u)   UPDATE=true; shift ;;
        --help|-h)     usage ;;
        --*) echo "${red}Unknown option:${rst} $1"; usage ;;
        *) TARGET_PATH="$1"; shift ;;
    esac
done

# --- resolve target ---
if [[ -z "$TARGET_PATH" ]]; then
    read -r -p "Enter path to target project: " TARGET_PATH
fi
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"

# --- pre-flight -----------------------------------------------------------
header "Pre-flight"

# 1. target exists?
if [[ ! -d "$TARGET_PATH" ]]; then
    fail "Target directory '$TARGET_PATH' does not exist."
    exit 1
fi

# resolve to absolute path
TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
    fail "Cannot access '$TARGET_PATH'."
    exit 1
}
ok "Target: $TARGET_PATH"

# 2. write permission?
if [[ ! -w "$TARGET_PATH" ]]; then
    fail "No write permission on '$TARGET_PATH'."
    exit 1
fi
ok "Write permission: yes"

# 3. already installed? compare versions
AGENT_DIR="$TARGET_PATH/.agent"
SRC_DIR="$AGENT_DIR/src"
VERSION="$(cat "$METAAGENT_SRC/VERSION" 2>/dev/null || echo '?')"

# The version is not decoration: it is written into .agent/checkpoints.json,
# whose schema pins it to ^[0-9]+\.[0-9]+\.[0-9]+$. A malformed VERSION would
# produce a checkpoints file that no protocol can trust, so the installer
# stops here instead of writing one.
if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    fail "framework/VERSION is '$VERSION' — not a MAJOR.MINOR.PATCH version."
    fail "INIT writes it into .agent/checkpoints.json, and checkpoints-schema.json requires that shape."
    exit 1
fi

if [[ -f "$SRC_DIR/VERSION" ]]; then
    OLD_VER="$(cat "$SRC_DIR/VERSION" 2>/dev/null || echo '?')"
    if [[ "$OLD_VER" != "$VERSION" ]]; then
        info "Existing MetaAgent v${OLD_VER} found → upgrading to v${VERSION}"
    else
        skip "MetaAgent v${VERSION} already installed (use --update to reinstall)"
        if [[ "$CHECK" == false ]]; then
            warn "No changes applied. Run with --update to overwrite existing files."
        fi
    fi
else
    info "Fresh install: MetaAgent v$VERSION"
fi

# 4. summary
AGENTS_MD="$TARGET_PATH/AGENTS.md"
RULES_DIR="$AGENT_DIR/rules"
DECISIONS_DIR="$AGENT_DIR/decisions"
TASKS_DIR="$AGENT_DIR/tasks"
CONTEXT_DIR="$AGENT_DIR/context"
ARCHIVE_DIR="$AGENT_DIR/archive"
ARCHIVE_TASKS_DIR="$ARCHIVE_DIR/tasks"
ARCHIVE_DECISIONS_DIR="$ARCHIVE_DIR/decisions"
ARCHIVE_CHECKPOINTS_DIR="$ARCHIVE_DIR/checkpoints"
REQUESTS_DIR="$AGENT_DIR/requests"
REQUESTS_ACTIVE_DIR="$REQUESTS_DIR/active"
REQUESTS_ARCHIVE_DIR="$REQUESTS_DIR/archive"
ROADMAP_DIR="$AGENT_DIR/roadmap"
ROADMAP_ARCHIVE_DIR="$ROADMAP_DIR/archive"
TEMP_DIR="$TARGET_PATH/.temp"
ARCHIVE_REQUESTS_DIR="$ARCHIVE_DIR/requests"
CHECKPOINTS_JSON="$AGENT_DIR/checkpoints.json"
PROJECT_RULES_MD="$RULES_DIR/project-rules.md"
DECISIONS_INDEX_JSON="$DECISIONS_DIR/index.json"
GITIGNORE="$TARGET_PATH/.gitignore"

if [[ "$CHECK" == true ]]; then
    echo ""
    info "INIT artefacts (a real run would create the missing ones, and only those):"
    for f in "$CHECKPOINTS_JSON" "$PROJECT_RULES_MD" "$DECISIONS_INDEX_JSON" "$GITIGNORE" "$AGENTS_MD"; do
        if [[ -f "$f" ]]; then
            skip "${f#$TARGET_PATH/} (exists — kept as is)"
        else
            info "${f#$TARGET_PATH/} (would be created)"
        fi
    done
    if [[ -d "$TEMP_DIR" ]]; then
        skip ".temp/ (exists)"
    else
        info ".temp/ (would be created)"
    fi
    echo ""
    info "${ylw}--check mode:${rst} all checks passed, no changes applied."
    exit 0
fi

# --- phase 1: directories ------------------------------------------------
header "Directories"

mkdir -p "$SRC_DIR" "$RULES_DIR" "$DECISIONS_DIR" "$TASKS_DIR" "$TASKS_DIR/backlog" \
         "$CONTEXT_DIR" "$ARCHIVE_DIR" "$ARCHIVE_TASKS_DIR" "$ARCHIVE_DECISIONS_DIR" \
         "$ARCHIVE_REQUESTS_DIR" "$ARCHIVE_CHECKPOINTS_DIR" \
         "$REQUESTS_ACTIVE_DIR" "$REQUESTS_ARCHIVE_DIR" \
         "$ROADMAP_DIR" "$ROADMAP_ARCHIVE_DIR" \
         "$TEMP_DIR"

for d in "$SRC_DIR" "$RULES_DIR" "$DECISIONS_DIR" "$TASKS_DIR" "$TASKS_DIR/backlog" \
         "$CONTEXT_DIR" "$ARCHIVE_DIR" "$ARCHIVE_TASKS_DIR" "$ARCHIVE_DECISIONS_DIR" \
         "$ARCHIVE_REQUESTS_DIR" "$ARCHIVE_CHECKPOINTS_DIR" \
         "$REQUESTS_ACTIVE_DIR" "$REQUESTS_ARCHIVE_DIR" \
         "$ROADMAP_DIR" "$ROADMAP_ARCHIVE_DIR" \
         "$TEMP_DIR"; do
    short="${d#$TARGET_PATH/}"
    if [[ -d "$d" ]]; then
        ok "$short"
    else
        fail "$short (creation failed)"
    fi
done

# --- phase 2: files ------------------------------------------------------
header "Files"

COPY_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

copy_file() {
    local src="$1" dst_dir="$2"
    local name; name="$(basename "$src")"
    local dst="$dst_dir/$name"
    if [[ ! -f "$src" ]]; then
        skip "$name (source not found)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        return
    fi
    if [[ "$UPDATE" == true ]] || [[ ! -f "$dst" ]]; then
        if cp "$src" "$dst"; then
            ok "$name"
            COPY_COUNT=$((COPY_COUNT + 1))
        else
            fail "$name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        skip "$name (exists, use --update to overwrite)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
    fi
}

copy_dir() {
    local src="$1" dst_dir="$2"
    local name; name="$(basename "$src")"
    local dst="$dst_dir/$name"
    if [[ ! -d "$src" ]]; then
        skip "$name/ (source not found)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        return
    fi
    mkdir -p "$dst"
    if [[ "$UPDATE" == true ]]; then
        if cp -rf "$src"/* "$dst/" 2>/dev/null; then
            ok "$name/"
            COPY_COUNT=$((COPY_COUNT + 1))
        else
            fail "$name/ (partial copy)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        cp -rn "$src"/* "$dst/" 2>/dev/null || true
        ok "$name/"
        COPY_COUNT=$((COPY_COUNT + 1))
    fi
}

copy_file "$METAAGENT_SRC/GUIDE.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/BOUNDARIES.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/CHANGELOG.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/WORKFLOW.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/README.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/AGENTS.template.md" "$SRC_DIR"
copy_file "$METAAGENT_SRC/VERSION" "$SRC_DIR"
copy_dir  "$METAAGENT_SRC/PROTOCOLS" "$SRC_DIR"
copy_dir  "$METAAGENT_SRC/COMMANDS"  "$SRC_DIR"
copy_dir  "$METAAGENT_SRC/TEMPLATES" "$SRC_DIR"
copy_dir  "$METAAGENT_SRC/FUTURE"    "$SRC_DIR"
copy_file "$METAAGENT_SRC/install.sh" "$SRC_DIR"

# --- phase 3: INIT artefacts ---------------------------------------------
# 00_INIT.md §0.4 and §0.6-§0.9. These files are the DATA OF THE PROJECT, not
# the kit: they are written when absent and NEVER overwritten — `--update` is
# about `.agent/src/`, and an installer that rewrote checkpoints.json or
# project-rules.md would destroy the only state the phases read.
header "INIT artefacts (written only if absent — never overwritten)"

INIT_CREATED=0
INIT_KEPT=0

# _json_str <text> — the body of a JSON string: backslash and double quote
# escaped. A path is the only thing that goes in here, and a path may hold both.
_json_str() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

# _uuid — a session id. /proc first (Linux), uuidgen second (git-bash with
# coreutils), /dev/urandom third: the kit must install on a host that has
# neither python3 nor the director.
_uuid() {
    if [[ -r /proc/sys/kernel/random/uuid ]]; then
        tr -d '\r\n' < /proc/sys/kernel/random/uuid
        return 0
    fi
    if command -v uuidgen >/dev/null 2>&1; then
        uuidgen | tr 'A-Z' 'a-z' | tr -d '\r\n'
        return 0
    fi
    local h
    h="$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n\r')"
    if [[ "${#h}" -ne 32 ]]; then
        printf '00000000-0000-4000-8000-%012d' "$$"
        return 0
    fi
    printf '%s-%s-4%s-8%s-%s' "${h:0:8}" "${h:8:4}" "${h:13:3}" "${h:17:3}" "${h:20:12}"
}

# _write_atomic <dst> — stdin to <dst> through tmp + mv: a half-written
# checkpoints.json is a checkpoint no phase can read.
_write_atomic() {
    local dst="$1" tmp="$1.tmp.$$"
    cat > "$tmp" && mv "$tmp" "$dst"
}

# _init_absent <dst> <label> — the one rule for every INIT artefact: write it
# when it is not there, keep it when it is.
_init_absent() {
    if [[ -f "$1" ]]; then
        skip "$2 (exists — kept as is)"
        INIT_KEPT=$((INIT_KEPT + 1))
        return 1
    fi
    return 0
}

# .agent/rules/project-rules.md — 00_INIT.md §0.6, from TEMPLATES/.
if _init_absent "$PROJECT_RULES_MD" "rules/project-rules.md"; then
    if [[ -f "$METAAGENT_SRC/TEMPLATES/project-rules.md" ]]; then
        if cp "$METAAGENT_SRC/TEMPLATES/project-rules.md" "$PROJECT_RULES_MD"; then
            ok "rules/project-rules.md (from TEMPLATES/project-rules.md)"
            INIT_CREATED=$((INIT_CREATED + 1))
        else
            fail "rules/project-rules.md"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        fail "rules/project-rules.md (TEMPLATES/project-rules.md is missing from the kit)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

# .agent/decisions/index.json — 00_INIT.md §0.7, the machine-readable ADR
# index that 02_ROADMAP.md §"если существует" and 06_METASTATE.md read. Shape
# from TEMPLATES/schemas/decisions-index-schema.json: version ∈ {2.0, 3.0},
# decisions is a list. No timestamps: created_at/updated_at are optional in
# the schema, and an empty index has no creation event to record.
if _init_absent "$DECISIONS_INDEX_JSON" "decisions/index.json"; then
    printf '{\n  "version": "3.0",\n  "decisions": []\n}\n' | _write_atomic "$DECISIONS_INDEX_JSON"
    ok "decisions/index.json (version 3.0, no decisions yet)"
    INIT_CREATED=$((INIT_CREATED + 1))
fi

# .agent/checkpoints.json — 00_INIT.md §0.8 literal, and it must satisfy
# TEMPLATES/schemas/checkpoints-schema.json: the eight phase names, the five
# statuses, metaagent_version as MAJOR.MINOR.PATCH, no key the schema does not
# declare. (The repo's own `.agent/checkpoints.json` is NOT the model: its
# statuses are free text like "completed (2026-10-27: ...)" and would violate
# the enum. This is built from the schema + the protocol, not copied.)
if _init_absent "$CHECKPOINTS_JSON" "checkpoints.json"; then
    {
        printf '{\n'
        printf '  "metaagent_version": "%s",\n' "$VERSION"
        printf '  "session_id": "%s",\n' "$(_uuid)"
        printf '  "target_repo": "%s",\n' "$(_json_str "$TARGET_PATH")"
        printf '  "goal": null,\n'
        printf '  "project_type": null,\n'
        printf '  "phases": {\n'
        printf '    "init": "completed",\n'
        printf '    "analyse": "pending",\n'
        printf '    "roadmap": "pending",\n'
        printf '    "design": "pending",\n'
        printf '    "decomposition": "pending",\n'
        printf '    "execution": "pending",\n'
        printf '    "metastate": "pending",\n'
        printf '    "handoff": "pending"\n'
        printf '  },\n'
        printf '  "tasks": [],\n'
        printf '  "last_updated": "%s"\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '}\n'
    } | _write_atomic "$CHECKPOINTS_JSON"
    ok "checkpoints.json (00_INIT.md §0.8, phases.init = completed)"
    INIT_CREATED=$((INIT_CREATED + 1))
fi

# .temp/ in .gitignore — 00_INIT.md §0.4. The comparison strips CR: a
# .gitignore with CRLF endings makes `grep -xF '.temp/'` answer "absent" for a
# line that IS there (AGENTS.md, ловушка 2), and the installer would append a
# duplicate line on every run — the opposite of idempotent.
if [[ -f "$GITIGNORE" ]] && tr -d '\r' < "$GITIGNORE" | grep -qxF '.temp/'; then
    skip ".gitignore (.temp/ already ignored)"
    INIT_KEPT=$((INIT_KEPT + 1))
elif [[ ! -f "$GITIGNORE" ]]; then
    printf '.temp/\n' > "$GITIGNORE"
    ok ".gitignore (created with the single line .temp/)"
    INIT_CREATED=$((INIT_CREATED + 1))
else
    # Append; every existing byte stays where it is. A file whose last line has
    # no trailing newline would otherwise swallow the new line into it.
    if [[ -n "$(tail -c 1 "$GITIGNORE")" ]]; then
        printf '\n' >> "$GITIGNORE"
    fi
    printf '.temp/\n' >> "$GITIGNORE"
    ok ".gitignore (appended .temp/)"
    INIT_CREATED=$((INIT_CREATED + 1))
fi

# --- phase 4: AGENTS.md (00_INIT.md §0.9) --------------------------------
# Rendered from AGENTS.template.md — the ONE description of what the project's
# AGENTS.md says. The installer used to carry a SECOND copy as a heredoc, and
# the two had already drifted (the heredoc lacked the requests/ADR rows and the
# "начни с METASTATE" step). {VERSION} is the only placeholder the template
# needs; the lifecycle line stays "v3.0" on purpose, because it names the
# MODEL, not the kit version (VERSION is 3.0.0).
header "AGENTS.md"

if [[ ! -f "$METAAGENT_SRC/AGENTS.template.md" ]]; then
    fail "AGENTS.md (AGENTS.template.md is missing from the kit)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
elif [[ -f "$AGENTS_MD" ]]; then
    # NEVER overwritten — not on the first run, not on --update. The file may
    # be the owner's, or an older MetaAgent's with local edits; the installer
    # cannot tell the two apart, and overwriting either is not recoverable.
    skip "AGENTS.md (exists — never overwritten, not even with --update)"
    INIT_KEPT=$((INIT_KEPT + 1))
else
    sed "s|{VERSION}|$VERSION|g" "$METAAGENT_SRC/AGENTS.template.md" | _write_atomic "$AGENTS_MD"
    ok "AGENTS.md (from AGENTS.template.md, {VERSION} → $VERSION)"
    INIT_CREATED=$((INIT_CREATED + 1))
fi

# --- summary -------------------------------------------------------------
header "Summary"
echo "  MetaAgent v$VERSION → $SRC_DIR"
echo ""
if (( COPY_COUNT > 0 )); then
    ok "${COPY_COUNT} kit file(s) copied"
fi
if (( SKIP_COUNT > 0 )); then
    skip "${SKIP_COUNT} kit file(s) skipped (already present — --update refreshes them)"
fi
if (( INIT_CREATED > 0 )); then
    ok "${INIT_CREATED} INIT artefact(s) created"
fi
if (( INIT_KEPT > 0 )); then
    skip "${INIT_KEPT} INIT artefact(s) already present (kept — never overwritten)"
fi
if (( FAIL_COUNT > 0 )); then
    fail "${FAIL_COUNT} file(s) failed"
fi
echo ""
echo "  INIT artefacts (checkpoints, rules, decisions, .gitignore, AGENTS.md) are"
echo "  the project's data: this installer writes them only when they are absent."
echo ""
if (( FAIL_COUNT == 0 )); then
    ok "Installation completed successfully."
else
    fail "Installation completed with ${FAIL_COUNT} error(s)."
    exit 1
fi
