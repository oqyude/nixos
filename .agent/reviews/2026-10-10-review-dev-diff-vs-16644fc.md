# Review of dev branch diff vs 16644fc

**Date:** 2026-10-10
**Reviewer:** Sisyphus (Sisyphus-Junior + oracle lanes; 3 oracle lanes INCONCLUSIVE due to model infra outage)
**Baseline:** `16644fc metaagent: install v3.0.0, migrate docs/arch/* → .agent/`
**Branch:** `dev`
**Diff:** 33 files changed, 155 insertions(+), 91 deletions(-)
**Scope:** `git diff HEAD` (staged + unstaged) — full audit of work done during `phases.execution = in_progress`

## Overall Verdict: **FAILED**

| # | Lane | Type | Verdict | Confidence | Note |
|---|------|------|---------|------------|------|
| 1 | Goal & Constraint | oracle | INCONCLUSIVE | — | All 3 fallback models unavailable (gpt-5.6-sol → gemini-3.1-pro → claude-opus-5) |
| 2 | QA Execution | Sisyphus-Junior | PASS | LOW | Static analysis only; `nix` not installed on Windows host |
| 3 | Code Quality | oracle | INCONCLUSIVE | — | Same model infra issue |
| 4 | Security | oracle | INCONCLUSIVE | — | Same model infra issue |
| 5 | Context Mining | Sisyphus-Junior | **FAIL** | HIGH | 1 BLOCKING + 3 IMPORTANT + 2 MINOR findings |

Aggregate: 3 INCONCLUSIVE + 1 FAIL + 1 PASS-low. Formally INCONCLUSIVE per
`/review-work` protocol, but **substantively FAILED** due to BLOCKING finding in
lane 5. Lanes 1/3/4 should be re-run once oracle models are reachable again.

---

## Blocking Issues (MUST fix)

### B1. R1.4 в project-rules.md и AGENTS.md содержит неверный список файлов для `100.64.0.0` (Tailscale-адрес sapphira)
- **Files:** `.agent/rules/project-rules.md:22-24`, `AGENTS.md:18-20`
- **Current (WRONG):** «Используется в `nginx.nix`, `nextcloud.nix` (`trusted_proxies`), `vds/systemd.nix`, **`vds/nginx.nix`**. При смене — править 4 файла.»
- **Actual (`grep -rn '100\.64\.0\.0' --include='*.nix'`):** `home/termux.nix:256`, `modules/server/nextcloud.nix:73`, `modules/server/nginx.nix:109,253`, `modules/vds/systemd.nix:10`
- **Why:** `vds/nginx.nix` no longer has `100.64.0.0` (upstream `server = "100.64.0.0"` was removed in `ef38dc4`). `home/termux.nix:256` has it (added in `958247b soft coding`) but R1.4 doesn't mention it. T12 was marked `completed` in both `checkpoints.json` AND `manifest.json` with stale invariant text.
- **Impact:** Anyone following R1.4 to "edit the 4 files" will open `vds/nginx.nix` (nothing to change) and miss `home/termux.nix:256` (one of 2 live SSH host entries). On Tailscale address change, this silently breaks SSH in `home/termux.nix:255-268`.
- **Fix:** Replace `vds/nginx.nix` → `home/termux.nix` in both lines of R1.4 (project-rules.md and AGENTS.md). Re-open T12 (mark `pending`), re-verify, re-close.

---

## Important Issues (should fix before merge)

### I1. "15 закомментированных модулей" в документации — фактически 14
- **Files:** `AGENTS.md:97`, `project-rules.md:97`, `manifest.json:264` (T16 acceptance)
- **Actual (`git show 16644fc:modules/server/default.nix | grep -c '^    # '`):** exactly 14 commented imports. 13 are in `archive/`, but **stirling-pdf.nix** was DELETED in `5dd7a58 nix flake update` (17-line `enable=false` stub; functionality absorbed into `bentopdf.nix` in same commit). **open-webui.nix** was never commented — was at `modules/server/open-webui.nix` (58333d0), migrated to `modules/containers/open-webui.nix`, still active via `modules/server/default.nix:5`.
- **Impact:** Documentation lies about 2 modules. T16 acceptance criterion misstates scope.
- **Fix:**
  - Update `modules/server/default.nix:37-40` comment to explain «14 archived, 1 (stirling-pdf) deleted in 5dd7a58, 1 (open-webui) still active in containers/».
  - `project-rules.md:97` «15 закомментированных модулей» → «14 закомментированных модулей (1 удалён, 1 активен)».
  - Same in `AGENTS.md:97`.
  - `manifest.json:264` T16 acceptance criterion — rewrite to reflect real scope.

### I2. T1 и T13 фактически исправлены, но `manifest.json` всё ещё помечает их как "pending"
- **Files:** `.agent/tasks/manifest.json:22` (T1.status="pending"), `:222` (T13.status="pending")
- **What's done:**
  - **T1:** diff fixes `configurations/mobile.nix:12` import (`lib/xlib.nix` → `lib/xlib`). Verified by static analysis: 0 residual `lib/xlib.nix` (with `.nix`) imports in active code. Resolves to `lib/xlib/default.nix`.
  - **T13:** diff removes `networking.firewall.allowedTCPPorts = [ 80 443 ]` from `modules/server/nginx.nix`, replaces with R1.3 comment.
- **Why pending:** T1 acceptance criterion #1 requires `nix flake check` to pass on `.#nixOnDroidConfigurations.epral` — never run (`nix` unavailable on Windows host). T13 needs `nix flake check` green on sapphira config too.
- **Fix:** Commit `.ci/checks.sh` (currently untracked), run on atoridu or sapphira, attach output, then mark T1/T13 as `completed` in `manifest.json`.

### I3. T1 acceptance criterion #1 never executed — `nix flake check` not run
- **Files:** `manifest.json:27` (T1), `project-rules.md:13` (R1.1)
- **What:** `nix` not installed on this Windows host. `.ci/checks.sh` exists (136 lines, implements 3 of 7 candidates from `analysis-report.md §5`) but is **untracked** (`.ci/` directory in `?? .ci/` from `git status`). R1.1 says «Закреплено через `nix flake check`» — no evidence of this in current session.
- **Impact:** T1 fix is correct statically, but acceptance criterion #1 is formally unmet. `.ci/checks.sh` must be committed and executed on any NixOS host before T1 can be marked `completed`.
- **Fix:** Commit `.ci/checks.sh` separately, run on atoridu (`bash .ci/checks.sh` or CI job), attach output to T1.

---

## Minor Issues (non-blocking)

### M1. R1.3 ссылается на `nginx.nix:225` — stale line number
- **Files:** `project-rules.md:20`, `AGENTS.md:20`
- **Fact:** After diff, `nginx.nix` is 377 lines; `allowedTCPPorts` is gone. Line 225 is now inside the `extraConfig` of `tty.zeroq.su` vhost.
- **Fix:** Remove line number, replace with «nginx.nix (networking.firewall)».

### M2. R1.2 lists 7 services, 2 of which (n8n, minecraft) are now in archive
- **File:** `project-rules.md:16-17`
- **Fact:** T4 actually covers 12 active services (postgresql, samba, homebox, gitea, navidrome, syncthing, uptime-kuma, immich, nextcloud, calibre-web, 3x-ui, tape-rotation). n8n and minecraft are now in archive.
- **Fix:** Update R1.2 to list the 12 actual services (or split into «active» / «archived»).

---

## Positive Findings (что сделано корректно)

- **T1 import fix** — `configurations/mobile.nix:12` correctly imports `../lib/xlib` (Nix resolves to `lib/xlib/default.nix`). No residual `lib/xlib.nix` (with `.nix`) anywhere.
- **T4 storage guard** — `mkStorageGuard` defined in `lib/xlib/helpers.nix:180-183`, anchored on `xlib.dirs.server-home` (= `/home/oqyude/External`), correctly avoiding the «bind-mount shares st_dev» trap documented in R1.2. Applied to exactly 12 services: postgresql:27, samba:76, homebox:33, gitea:32, navidrome:33, syncthing:18, uptime-kuma:26, immich:26, nextcloud:207, calibre-web:67, 3x-ui:76, tape-rotation backend:105 + frontend:114. Merge via `//` does not clobber upstream `serviceConfig` (NixOS submodule semantics).
- **T6 3x-ui migration notes** — `.agent/decisions/notes/3x-ui-xray-26.9.md` created (209 lines; original was 201, extended with explicit Verdict section). Verdict at lines 203-209: «Миграция 26.7.x → 26.9.x **провалена**. Причина: изменения в X25519MLKEM768 несовместимы с REALITY-инбаундом». R1.8 added in `project-rules.md:36-40`.
- **T8 3x-ui auto-update** — `podman-update-3xui_app` service and timer block fully removed. Rationale comment remains.
- **T9 R1.8** — `project-rules.md:36-40` explicitly says «версия ядра Xray — состояние UI-панели 3x-ui, не Nix».
- **T11 R1.3** — Router ports wording: 5 ports (22, 80, 443, 8443 xray, 22000 syncthing). T11 marked `completed` in checkpoints.json + manifest.json.
- **T13 nginx** — `networking.firewall.allowedTCPPorts = [ 80 443 ]` removed; replaced with R1.3 comment.
- **T16 archive** — 13 files renamed via `git mv` (`similarity index 100%`, content unchanged). Imports in `modules/server/default.nix:7-41` cleaned. (Issue I1 documents the documentation drift around the count.)
- **sops path compliance (R1.7)** — All 6 nextcloud-spreed-signaling secrets use `config.sops.secrets.<name>.path`, no `path = "..."` override. ADR-0001 holds.
- **CI** — `.ci/checks.sh` is well-formed (136 lines, `set -euo pipefail`, balanced bash arrays, proper exit codes).

---

## Architectural Observations (для следующих итераций, не блокеры)

- **mkStorageGuard** takes `xlib` as a parameter rather than being curried. A `mkGuardedService` wrapper (function that wraps the whole `systemd.services.<name>` block) would be safer — eliminates "forgot to wire it" human error. Refactor opportunity, MINOR.
- **`podman-update-taperotation` in `modules/containers/tape-rotation.nix:144-155`** — oneshot service without timer (timer commented out). Dead code. Either wire up timer or remove service. MINOR.
- **`nextcloud-spreed-signaling` disabled but 6 sops secrets still declared** (nextcloud-talk-secret, internal-secret, hashkey, blockkey, turn-secret, turn-api-key). Safe (sops-nix materializes, but they're unused), tech debt. When the service is re-enabled — secrets already in place.

---

## Recommended Fix Order

1. **Now (BLOCKING):** Fix R1.4 in `project-rules.md` and `AGENTS.md`: `vds/nginx.nix` → `home/termux.nix`. This is a documented invariant — if it lies, everything that depends on it (future Tailscale changes, new vhosts) goes wrong.
2. **Now (verification gap):** Run `bash .ci/checks.sh` on atoridu or sapphira. If green — mark T1, T2, T13, T8, T9 as `completed` in `manifest.json`. If red — there's a hidden bug in the diff.
3. **Before merge (docs sync):** Update AGENTS.md:97, project-rules.md:97, manifest.json:264 about «15 → 14 + 1 deleted + 1 active». Add rationale in `modules/server/default.nix:37-40`.
4. **Before merge (stale refs):** Remove `nginx.nix:225` → «nginx.nix (networking.firewall)». Update R1.2 from 7 services to 12 actual.
5. **Later (refactor):** Introduce `mkGuardedService` or type-checked wrapper around `mkStorageGuard` to remove the "forgot to attach" failure mode.

---

## INCONCLUSIVE Lanes — Context

Oracle agents (Goal, Code Quality, Security) failed with `ProviderModelNotFoundError` on all 3 fallback models. This is **infrastructure**, not a diff issue. If re-run is desired, use `task(category="ultrabrain", ...)` or `task(category="unspecified-high", ...)` to route to alternative models. Findings from Context Mining + QA + my own reading of all critical files were sufficient for an actionable verdict — recommend fixing B1, I1–I3 first, then deciding whether to re-run Oracle passes.

## Worktree Cleanup

Review worktree at `C:\Users\oqyude\AppData\Local\Temp\opencode\review-dev` (branch `review/dev-baseline`, HEAD 16644fc) was created, used, and removed. Main worktree `S:\Git\nixos` was never modified by the review process. Full diff preserved in main worktree (33 modified + 4 untracked).
