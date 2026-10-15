# Handoff Summary

## Session Summary

**Session:** metaagent-director-2026-10-15 (продолжение после 2026-10-15T03:00, **закрыто 2026-10-15T15:00**)
**Goal:** поднять herdr на sapphira + rydiwo, опубликовать webui на `https://herdr.zeroq.su`, написать черновик `metaagent-director` (директор-агент, управляющий worker-сессиями через herdr).
**Completed:** 9 задач этого прохода (T21–T27 saga setup + T33 saga close-out + T18, T32 cleanup формализация, см. `tasks/manifest.json`)
**Pending:** 3 прошлых (T3, T4, T10) + 1 fix (T20 — `.ci/checks.sh` mode bit) + 4 новых (T28–T31), см. ниже
**Hosts:** sapphira (192.168.1.20) + rydiwo (192.168.1.102) — оба с `home/modules/herdr.nix`, оба с `home/modules/herdr-runtime.nix` (bun + nodejs_22), оба с `herdr-web-ui@439ad38d091c02c3e4747956808dbac2305702d3` в `/home/oqyude/.config/herdr/plugins/github/devswha.herdr-web-ui-210f619d6b7b/`

---

## ⚠️ Незакоммиченная работа

| Где | Что |
|---|---|
| `S:\Git\metaagent-director\AGENTS.md` (297 → 604 строк) | **полностью переписан** под v0.2: multi-session model (1 opencode serve + N sessions вместо N процессов). Директор, цикл, examples, red lines, version. Не закоммичен — отдельный репо, не nixos. |
| `S:\Git\metaagent-director\README.md` (2 → 64 строки) | Описание репо, архитектура, сценарии использования. |

### Запушено в `gitea/dev` после прохода (2026-10-15T13:45)

| Commit | Что |
|---|---|
| `034bb5e` | `feat(home): add herdr import to rydiwo config (multi-host bridge)` — `home/secondary.nix` теперь в git, до этого жил только scp-копией на rydiwo |
| `4bf8e55` | `docs(agents): sync R1.15, ADR-0005, T21-T32 from metaagent-director-2026-10-15` — meta-agent state (handoff, tasks/manifest.json, checkpoints.json, AGENTS.md, project-rules.md, decisions/0005, decisions/index.json) синхронизирован с реальностью |

### ⏳ Следующее физическое действие (не коммит-исход)

**На sapphira выполнить `deploy .#rydiwo`** — до этого herdr на rydiwo живёт из scp-копии (intent-to-add на rydiwo's git tree), а не из `/nix/store`. Пока этого не сделано:
- sapphira → `herdr --machine rydiwo …` формально работает (herdr бинарь на rydiwo есть), но при изменениях herdr или system-уровня rydiwo (например, апгрейд nixpkgs) мост может «упасть» с впечатлением «sapphira пытается что-то императивно доставить»;
- декларативное правило проекта «всё через Nix» для rydiwo's herdr не выполнено до конца;
- любые правки `home/modules/herdr.nix` не дойдут до rydiwo до тех пор, пока deploy не запустят.

После deploy ожидаемо (verify в `tasks/manifest.json:T22.verify_after_deploy`):
- `systemctl --user status herdr` на rydiwo → `active`, `ExecStart=…/herdr server --session herdr-prod`
- `~/.config/herdr/sessions/herdr-prod/herdr.sock` mode 0600
- `git -C /etc/nixos status` на rydiwo → clean tree (scp-копия слилась с git pull)

---

## Completed (этот проход)

### herdr как инфраструктура
- **`home/modules/herdr.nix`** — новый home-manager user unit. `ExecStart = ${pkgs.herdr}/bin/herdr server --session herdr-prod`, `EnvironmentFile = xlib.dirs.opencode-server-env` (sops opencode_server secret), `MemoryHigh=2G MemoryMax=4G`, `Restart=always` (митигирует herdr bug #4920 про shutdown after last detach), `WantedBy=default.target`. Паттерн зеркалит существующий `home/modules/opencode.nix`. Linger=true у пользователя (modules/users.nix:75) — сервис живёт без активной сессии.
- **`home/server.nix`** — добавлен `imports = [ ./modules/herdr.nix ]`.
- **`home/secondary.nix`** — то же для rydiwo.
- **`modules/server/nginx.nix`** — vhost `herdr.zeroq.su` (forceSSL, ACME, WebSocket). Три эволюции: (а) authelia forward-auth + exempt `/api/(auth|devices/pair|health)` для POST, (б) убрана authelia целиком после понимания sameOrigin-лимита bun-сервера, (в) убраны дублирующие `proxy_set_header` (NixOS `recommendedProxySettings` уже добавляет Host/X-Forwarded-Proto/X-Forwarded-Host через include; явные строки → двойные значения в заголовке → 403).
- **`modules/server/coredns.nix`** — `192.168.1.20 herdr.zeroq.su` в hosts-блоке zeroq.su.

### herdr-web-ui plugin
- `herdr plugin install -y devswha/herdr-web-ui` → v0.4.8 на sapphira.
- **API token** в `~/.config/herdr/plugins/config/devswha.herdr-web-ui/env` mode 0600: `HERDR_WEB_TOKEN=134aec5cf22390e4b9826df51ba9b27d5208fcdbcd8b4e237ac2e642692241a1` (256 бит).
- **In-place PATCH** в `server/machine-security.ts` (`.orig` сохранён рядом) — добавляет поддержку `X-Forwarded-Host` в `sameOrigin()`. Без патча каждый cross-origin POST за reverse proxy возвращает 403 `invalid_origin`: функция сравнивает `new URL(request.url).origin` (видит `http://127.0.0.1:7317`, потому что это TCP-назначение proxy_pass) с браузерным `Origin: https://herdr.zeroq.su` — никогда не совпадает. **Maintenance caveat:** `herdr plugin update devswha.herdr-web-ui` затрёт патч; долгосрочно — форк + `herdr plugin link`.

### Multi-host setup
- `herdr machine add oqyude@rydiwo` на sapphira → машина зарегистрирована: `7e7a9f99aee73d76562b567b6b0ff84c | rydiwo | enabled`.
- С sapphira: `herdr --machine rydiwo workspace list` / `herdr --machine rydiwo status server` работают (через SSH к rydiwo).
- herdr на rydiwo: pid активен, сокет `~/.config/herdr/sessions/herdr-prod/herdr.sock` (mode 0600), `--session herdr-prod`. Cgroup 2G/4G, 4 cores, 11 GB RAM, 26 GB free.

### metaagent-director (отдельный репо `S:\Git\metaagent-director\`)
- **`AGENTS.md`** — контракт director-агента: identity, operating environment, 7-step cycle, managed repos (`director.config.toml` + auto-discovery fallback), worker lifecycle (spawn / monitor / retire), state layout в `state/`, red lines, examples. **v0.2**: workers = opencode sessions в одном long-lived `opencode serve`, не N процессов. Reason: per-process RSS ~800M, cgroup 4G не вмещает 3-4 subprocesses; one server + N sessions = ~1G total. `OPENCODE_CONFIG_CONTENT='{"agent":{"build":{"steps":200}}}'` env — cap против opencode bug #55076 (server resume после рестарта с default limits).
- **`README.md`** — human overview: что это, файлы, как взаимодействовать, ASCII-диаграмма архитектуры.

---

## Pending

### Из прошлого (без изменений)
| ID | Задача | Статус |
|---|---|---|
| T3 | Финальная политика nftables на VDS | pending, требует обсуждения с владельцем (откатывалось) |
| **T4** | Guard на несмонтированный `/mnt/services` | **pending, severity: high** — гвард мёртв на 13 юнитах/12 сервисах (см. `tasks/manifest.json:T4.notes`) |
| T10 | Судьба `reality443Forwarding` | pending, откатывалось; решение (а) «оставить» уже применено в коде |

### Новые (T21–T32)
| ID | Задача | Статус |
|---|---|---|
| T21 | herdr user service на sapphira | **completed** (commit в `dev`) |
| T22 | herdr user service на rydiwo | **completed, fix_landed 2026-10-15T13:45** (commit `034bb5e`, в `gitea/dev`); следующий физический шаг — `deploy .#rydiwo` на sapphira, см. ниже «Следующее физическое действие» |
| T23 | vhost `herdr.zeroq.su` с authelia→drop authelia | **completed** (commits 61ad57a, 9bf9407) |
| T24 | herdr-webui plugin install + token | **completed** |
| T25 | multi-host herdr setup (sapphira↔rydiwo machine) | **completed** |
| T26 | metaagent-director v0.2 docs (AGENTS.md + README.md) | **completed** (uncommitted в `S:\Git\metaagent-director\`) |
| T27 | ADR-0005: herdr-webui + sameOrigin patch | **completed** (записан в этом проходе) |
| T28 | v0.2 implement: единичный `opencode serve` на sapphira с `OPENCODE_CONFIG_CONTENT` cap | **pending** — директор v0.2 описан в `metaagent-director/AGENTS.md`, но **env-инжекция ключа не решена**. Текущий запуск на 4097 (test instance) **не работает**: agent принимает промпт, не вызывает LLM (status=None, tokens=0). Root cause: `GEMINI_API_KEY` (sops через `opencode-web.service`) не пробрасывается в мой standalone `opencode serve` на 4097. |
| T29 | In-place PATCH в `devswha/herdr-web-ui` upstream — добавить `x-forwarded-host` в `sameOrigin()` | **pending, severity: medium** — `herdr plugin update` затрёт локальный патч |
| T30 | Open question: какой use case для multi-host (T25)? | **pending, requires owner** — user сказал "чтобы видеть rydiwo в одной панели с sapphira" — но пока непонятно, как часто будет нужно, и нужен ли сценарий "массовый fan-out" |
| T31 | Quota handling examples в `metaagent-director/AGENTS.md` обновить под v0.2 (сейчас используют `herdr pane read`; в multi-session — opencode API) | **pending** — низкий приоритет, директорские циклы с quota hit — пользователь не сразу до них дойдёт |
| T32 | `T18` в `tasks/manifest.json` — отметить completed (gitea-runner fix уже в `dev` через `9bf9407` + связанные commits). | **completed 2026-10-15T14:30** — T18/T19/T32 cleanup формализован в metaagent-director-2026-10-15T14:30; см. saga close-out ниже |

---

## Главная развилка по итогам прохода: opencode API ≠ research claims

В `metaagent-director/AGENTS.md` v0.2 задокументирован multi-session flow как `POST /api/session/{id}/prompt` с телом `{"prompt": {"text": "..."}}`. **Smoke test на sapphira выявил расхождения с research-данными:**

1. **Создание session:** `directory` в теле POST **игнорируется**. Правильное поле — `{"location": {"directory": "/etc/nixos"}}`. Атрибуция: `agents/opencode/server/index.ts:1850+` (нужно верифицировать перед фиксацией AGENTS.md).
2. **Prompt endpoint:** `/api/session/{id}/prompt` принимает тело `{"prompt": {"text": "..."}}`. Тип значения `prompt` — `PromptInput` (не строка). 400 ошибка с подсказкой `"Expected PromptInput, got 'hi'"`.
3. **Сообщения:** `GET /api/session/{id}/messages` возвращает **HTML (SPA shell)**, не JSON. Возможно, в v1.19.0 messages читаются через `/api/session/{id}` (поле `messages` встроено в session DTO), а не отдельный endpoint — нужно подтвердить чтением `server/index.ts` перед merge.
4. **Конфиг:** `OPENCODE_CONFIG_CONTENT` через `nix shell -c` инверсия ломала скобки (`${agent:{build:{steps:200}}}`), env не доезжал до runtime. **Рабочий pattern** — вынести config в файл и подключать через `EnvironmentFile=`, либо использовать systemd `Environment=` с single-quoted JSON.
5. **Provider auth:** opencode читает `/run/secrets/opencode_auth` (sops) для провайдера `minimax-coding-plan`, **но** runtime дополнительно требует `GEMINI_API_KEY` в env (sops через `opencode-web.service` systemd unit). Standalone `opencode serve` без этого env запускается, но `cost/tokens = 0` — agent не вызывает LLM.

**Следствие для director v0.2:** сейчас не реализуемо без systemd user unit `opencode-director.service`, который инжектит все нужные env (включая `GEMINI_API_KEY`) + `OPENCODE_CONFIG_CONTENT` (как file-via-EnvironmentFile, не как inline JSON). Этот unit — следующий шаг после T28.

---

## Изменения против предыдущего handoff (2026-10-15T03:00)

| Что | Было | Стало |
|---|---|---|
| Hosts с herdr | sapphira (deployed в 9bf9407+herdr.service) | sapphira + **rydiwo** (оба через `home/modules/herdr.nix`) |
| vhosts | 12 на `*.zeroq.su` | **+1** (`herdr.zeroq.su` → 127.0.0.1:7317, herdr-webui Bun server) |
| Web UI | `tty.zeroq.su` (ttyd) | `tty.zeroq.su` + `herdr.zeroq.su` (chat + terminal panes) |
| Auth model для herdr.zeroq.su | — | `herdr_web_token` (256 бит, 1 год cookie lifetime) — НЕ authelia (см. ADR-0005) |
| Multi-host control | — | `herdr machine add oqyude@rydiwo` — sapphira видит rydiwo как удалённую панель |
| metaagent-director | — | новый репо `S:\Git\metaagent-director\`, AGENTS.md v0.2 (multi-session opencode model) |
| SameOrigin patch в bun-сервере | — | in-place patch в `server/machine-security.ts` (НЕ upstream-merged) |
| R1.15 | — | новый инвариант (см. project-rules.md) |
| ADR-0005 | — | новый ADR (см. `decisions/0005-herdr-webui-no-authelia.md`) |

---

## Project State (обновлено)

- **7 outputs** + epral (T2, без изменений)
- **20+ системных сервисов на sapphira** (без изменений в составе, но T13 завершён)
- **herdr user service:** sapphira + rydiwo (оба через `home/modules/herdr.nix`; на rydiwo **декларативно в git** с 034bb5e, **деплой из /n/Nix-store ждёт `deploy .#rydiwo` на sapphira**)
- **herdr-webui plugin** на sapphira, listen 127.0.0.1:7317, `OPENCODE_CONFIG_CONTENT` cap на 200 steps (митигация opencode bug #55076)
- **herdr machines:** 1 (rydiwo), SSH-доступ из sapphira работает
- **vhosts на `*.zeroq.su`:** 13, из них 1 (herdr.zeroq.su) — без authelia, только herdr token
- **Открытые контейнеры:** 4 (без изменений)
- **3x-ui/Xray:** заморожен (R1.10-R1.13, без изменений)
- **Tailscale:** `100.64.0.0` = sapphira (R1.4, без изменений)
- **3 нерешённых прошлых** (T3, T4, T10) + **5 pending этого прохода** (T20, T28–T31) — всего 8 открытых

---

## Next Steps

1. **`deploy .#rydiwo` на sapphira** — следующее физическое действие. До него herdr на rydiwo живёт из scp-копии (intent-to-add), а не из `/nix/store`; см. раздел «⏳ Следующее физическое действие (не коммит-исход)» в начале этого файла и `tasks/manifest.json:T22.next_action_required`.
2. **`herdr plugin update devswha/herdr-web-ui`** — отложить, пока патч in-place не смержен в upstream. Иначе сразу после `update` все cross-origin POST → 403 (см. ADR-0005).
3. **T28** — реализовать v0.2: написать `modules/services/opencode-director.nix` (или home-manager `services.opencode`) — systemd user unit `opencode-director.service` на `127.0.0.1:4097`, `EnvironmentFile=opencode-director.env` (sops + `OPENCODE_CONFIG_CONTENT` через file), `MemoryHigh=3G MemoryMax=4G`. После этого директор из `metaagent-director/AGENTS.md` сможет реально стартовать в herdr.
4. **T29** — PR в `devswha/herdr-web-ui` с патчем `sameOrigin()`. Долгосрочно правильно, но требует форка и поддержки.
5. **T4 (severity:high)** — единственный открытый вопрос, требующий кода (не обсуждения). Перенести `ConditionPathIsMountPoint` в `systemd.services.<name>.unitConfig`. Подробности в `tasks/manifest.json:T4.notes`.
6. **Коммиты в `S:\Git\metaagent-director\`** — `AGENTS.md` + `README.md` (v0.2 draft), `git add AGENTS.md README.md && git commit -m "docs: v0.2 — multi-session opencode model"`.

---

## Key Artifacts

- **State:**
  - `.agent/checkpoints.json` — phases (execution → completed, metastate → completed, handoff → in_progress; зафиксировано в коммите `4bf8e55` от 2026-10-15T13:30)
  - `.agent/tasks/manifest.json` — 23+ задач (включая T21-T32)
  - `.agent/context/project-state.md` — обновляется в `S:\Git\nixos\.agent\context\`
  - `.agent/roadmap/sources.md` — без изменений в этом проходе
- **Rules:**
  - `.agent/rules/project-rules.md` — добавлен R1.15 (см. ADR-0005)
  - `AGENTS.md` — добавлен инвариант #12 (R1.15 короткая версия)
- **Decisions:**
  - `.agent/decisions/0005-herdr-webui-no-authelia.md` — НОВЫЙ (см. ADR-0005)
  - `.agent/decisions/index.json` — зарегистрирован 0005
- **Code (в `S:\Git\nixos\`, все в `dev` через gitea):**
  - `home/modules/herdr.nix` (новый)
  - `home/server.nix` (импорт herdr.nix)
  - `home/secondary.nix` (импорт herdr.nix, **закоммичен в `034bb5e` и запушен в `gitea/dev`**)
  - `modules/server/nginx.nix` (vhost + 2-evolution commit)
  - `modules/server/coredns.nix` (DNS)
- **Code (в `S:\Git\metaagent-director\`, не закоммичен):**
  - `AGENTS.md` (v0.2 director contract)
  - `README.md` (human overview)
- **Plugins (на sapphira):**
  - `~/.config/herdr/plugins/config/devswha.herdr-web-ui/env` (mode 0600) — `HERDR_WEB_TOKEN`
  - `~/.config/herdr/plugins/github/devswha.herdr-web-ui-210f619d6b7b/server/machine-security.ts` (PATCHED, `.orig` сохранён рядом как upstream-версия от первой установки, `.patched.bak` — текущая пропатченная копия для быстрого restore после `git pull`)
- **Machines:**
  - sapphira herdr-prod session: `7e7a9f99aee73d76562b567b6b0ff84c` (sapphira local)
  - rydiwo machine: `7e7a9f99aee73d76562b567b6b0ff84c` (registered from sapphira)

---

## Saga close-out: 2026-10-15T14:30–15:00 — herdr multi-host end-to-end + plugin-runtime NixOS fix

**Контекст:** после T22 (home/secondary.nix:30 добавлен импорт `./modules/herdr.nix`, закоммичен в `034bb5e`) — пользовательский репорт «rydiwo — Connection failed / Could not start dynamically linked executable: bun». Saga — три слоя фиксов + plugin update + closeout docs.

**Слой 1: bun в shell PATH (FFD85DC, потом SUBSUMED в 7F30176).** Добавил `home.packages = with pkgs; [ bun ];` в `home/secondary.nix`. **Не помогло** — herdr-web-ui plugin использует собственный runtime manager (`install.<hash>/runtime/bin/bun`), не fallback на PATH. Установка bun в PATH нужна для preflight.sh, но не чинит запуск скачанного bun'а.

**Слой 2: programs.nix-ld (DFCD7F5).** В `modules/essentials/packages.nix:114` было закомментировано `# nix-ld.enable = true;` (кто-то рассматривал, не дошёл). Раскомментировал + добавил `stdenv.cc.cc.lib` (glibc + libstdc++ + libgcc_s). Это позволило glibc-based bun'у из plugin runtime manager стартовать.

**Слой 3: nodejs_22 в herdr-runtime.nix (2AB4851).** preflight.sh плагина после прохождения bun-проверки упал на «herdr web ui needs Node 18 or newer for its terminal sidecar». Добавил `pkgs.nodejs_22` в новый `home/modules/herdr-runtime.nix` (вынес из opencode.nix в единый источник, импортируется server.nix + secondary.nix).

**Refactor: herdr-runtime.nix как единый источник (7F30176).** pkgs.bun и pkgs.nodejs_22 теперь в одном месте, импортируются обоими `server.nix` и `secondary.nix`. Из `home/modules/opencode.nix` `pkgs.bun` убран из `home.packages` (оставлен в `programs.opencode.extraPackages` для `--suffix PATH` opencode-wrapped env — это другой PATH, не дубликат).

**Plugin update на sapphira (РУЧНАЯ работа, см. ADR-0005).** sapphira был на `79beb36`, rydiwo на `439ad38`. Привести sapphira к общему — `git pull origin main` + `bun install` + `bun run build` + **главный gotcha: ручная правка `~/.config/herdr/plugins.json:source.resolved_commit`** (herdr plugin list читает из этого JSON, а не из .git/HEAD плагина — git pull + bun build этого поля не обновляют). Без шага с правкой JSON herdr plugin list упорно показывает старый коммит. После правки + `systemctl --user restart herdr` → оба на `439ad38d091c02c3e4747956808dbac2305702d3`. in-place patch (`server/machine-security.ts` с `x-forwarded-host`) сохранён через `cp active → .patched.bak` + `git checkout -- file` + `cp .patched.bak active`.

**Выводы (что зафиксировано в ADR-0005 «Runtime prerequisites на NixOS»):**

1. **`pkgs.bun` в shell PATH** обязателен (для preflight.sh plugin'а и для всего окружения, где запускается herdr). Источник: `home/modules/herdr-runtime.nix`.
2. **`pkgs.nodejs_22` в shell PATH** обязателен (preflight.sh плагина проверяет `node --version`). Тот же источник.
3. **`programs.nix-ld.enable = true` глобально** обязателен для запуска **собственного** bun'а плагина (директива `[Unit]` для stub ld). Системный bun из п.1 НЕ помогает.
4. **`herdr plugin list` читает `source.resolved_commit` из `~/.config/herdr/plugins.json`**, не из `.git/HEAD` плагина. git pull + bun build не обновляют это поле — нужно править JSON руками или `herdr plugin install --force`.
5. **Maintenance procedure in-place патча `server/machine-security.ts`** — 7-шаговая, отработана 2026-10-15 на переходе `79beb36 → 439ad38`. Полностью записана в ADR-0005 «Рабочая maintenance-процедура». До T29 (PR в upstream) — ручная работа на ~10 команд каждый plugin update.

**Что было обновлено в meta-state (commit T33):**
- ADR-0005: добавлена «Рабочая maintenance-процедура» + «Runtime prerequisites на NixOS»; старая maintenance procedure помечена как НЕПРАВИЛЬНАЯ.
- `decisions/index.json`: ADR-0005 — добавлены теги `nix-ld`, `runtime-manager`; resolution поле расширено с описанием процедуры и трёх NixOS prerequisite.
- `tasks/manifest.json`: T18 → completed (формальная отметка, fix в 9bf9407); T32 → completed (cleanup); T33 добавлен как documentation completed (saga close-out).

---

## Сессия metaagent-attempt-2026-10-15T20:25Z — попытка и отмена шима herdr → opencode serve

**Цель сессии:** снизить потребление памяти и LLM-списаний, централизовав opencode-агенты на общем `opencode-web.service` (127.0.0.1:4096). Идея: herdr в каждой панели вместо полного opencode-инстанса запускает `opencode attach http://127.0.0.1:4096 --dir $PWD` — тонкий клиент, N панелей делят один сервер.

**Что делал:**
- **ADR-0006** (PATH-шим + симлинк `~/.local/bin/opencode`), R1.16 в `project-rules.md`, инвариант 13 в `AGENTS.md`, T34 в `tasks/manifest.json` — зафиксировано в 3e85307.
- **Боевой тест 1 (после 3e85307):** шим из `Service.Environment` **не сработал** в живом herdr-воркспейсе — `command -v opencode` в интерактивной zsh-панели возвращал home-manager wrap `/etc/profiles/per-user/oqyude/bin/opencode`, herdr стартовал полный TUI с собственным LLM-аккаунтом. Причина: `/etc/static/zshrc` подгружает `oh-my-zsh.sh`, который **пересобирает `$PATH`** из своего plugin list (ripgrep, nodejs-22, bun, gh, ast-grep); наш шим-каталог вытесняется; home-manager wrap выигрывает.
- **Двухслойная схема (16a44b9):** добавлен `home.file."${home}/.local/bin/opencode".source` симлинк. `~/.local/bin` — первая запись в PATH после `~/.local/bin/env` (Nix-managed) и переживает пересборку oh-my-zsh. **Боевой тест 2 (2026-10-15T19:37):** `argv` процесса = `[…/opencode-1.19.0/bin/opencode, attach, http://127.0.0.1:4096, --dir, /tmp/attach-smoke]`, `ss` показал **только** ESTAB на 127.0.0.1:4096 (без внешних LLM-сокетов). Технически шим работал.

**Главное наблюдение, перевернувшее решение:** `opencode` в режиме `attach` ≈ **300 МБ RSS на воркспейс** (полный TUI-клиент с TUI-движком, LSP/MCP, плагинами; тот же бинарь, что и в обычном режиме). 2 воркспейса × 310 МБ attach ≈ столько же, сколько web-вкладки в браузере (~0 МБ на нашей RAM, рендер в браузере). Шим **централизует LLM** (нет своих LLM-счетов), но **не даёт экономии RAM**. Цель сессии — снизить потребление памяти — не достигнута, а LLM-централизация — побочный эффект, который в нашей текущей модели угроз не является необходимым.

**Сторонние director-альтернативы (рассмотрены, не внедрены):**
- `opencode-sessions@1.0.0` (npm, `malhashemi`) — `@opencode-ai/sdk@^0.15.18`, **pre-v1**, несовместим с opencode 1.19.
- `kdcokenny/opencode-workspace` (16 компонентов), `kdcokenny/opencode-background-agents` — активные, но не проверены с opencode v1.
- `@opencode-ai/sdk` v0.3x + своя обвязка — оставлено на потом (новая задача, не T35).

**Отмена (2026-10-15T20:25Z):**
- `git reset --hard 3d4f1f5` + `git push --force-with-lease gitea dev` — стёрты 4 коммита (`3e85307`, `16a44b9`, `158f08d`, `574ec27`); `dev` = `3d4f1f5` (nginx-фикс от другого агента).
- `nix build .#nixosConfigurations.sapphira.config.system.build.toplevel` rc=0, `nixos-rebuild switch` rc=0 (новый toplevel `3qki65iy7…`). `home/modules/herdr.nix` — ванильный, без шима. `~/.local/bin/opencode` — отсутствует.
- `herdr.service` перезапущен (PID 27752, `InvocationID d55aa7d2…`) — ванильный, `EnvironmentFile=…server.env`, без `Environment=`-override. Тест-воркспейс: `which opencode` в новой панели → home-manager wrap, `agent start opencode` запускает полный TUI (`argv = ["opencode"]`) — **поведение как до 3e85307**.

**Сохранённые данные (на случай будущего возврата):**
- `~/.cache/t34-attempt-backup/` (9 файлов, 178 КБ): две версии `herdr.nix` (3e85307 и 16a44b9), ADR-0006, изменённые `manifest.json` / `AGENTS.md` / `project-rules.md` / `index.json`, **применимый патч** `full-attempt.patch` (544 строки, `git apply` восстановит всё разом), `my-commits.reflog`.
- `metaagent-director/t34-herdr-attach-attempt.patch` — копия патча во втором репо.
- Git reflog: 4 коммита живы ещё ~30 дней (умолчание 90). Принудительно стереть раньше: `git reflog expire --expire=now --all && git gc --prune=now`. **Не делал** — без явной команды.

**Дополнительно в этой же сессии (мелкое, не откат):**
- Удалён мёртвый кеш `~/.cache/opencode/packages/@bybrawe/opencode-loop@latest/` (loop был удалён из git коммитом 3babee5, но кеш оставался; в `~/.config/opencode/opencode.json` и `tui.json` loop не зарегистрирован — был мёртв).
- `opencode-sessions` не установлен (несовместим с opencode v1; см. выше).

**Pending в следующую сессию (без изменений):** T3 (nftables, otreca), T4 (dead mount-guard, sapphira, severity:high), T10 (reality443Forwarding), T20 (`.ci/checks.sh` mode bit), T28-T31 (открытые вопросы metaagent-director v0.2). T35 (закрытая попытка шима) — **не повторять** без новой мотивации и/или director-модели.

**Предсуществующие doc-drift, отложенные до чистки метаданных:**
- `checkpoints.json:tasks` (T1-T20) расходится с `manifest.json:tasks` (T1-T33). `phases` тоже: `execution=completed` vs `execution=in_progress`. `source_of_truth = manifest.json`.
- `AGENTS.md` инвариант 12 заканчивается дублированным R1.14 (escapeSystemdPath). Правильный end-of-invariant-12 — `R1.15, ADR-0005`. Дубликат не от этой попытки шима, тянется с 2026-10-15T14:30.
- Оба зафиксированы в `checkpoints.json:resolved_doc_drift` (drift-checkpoints-vs-manifest-tasks, drift-agentsmd-invariant12-dup-r114, drift-checkpoints-phases-vs-manifest), `resolved_at = null`, `deferred_to = следующая сессия` по решению владельца.

---

## ⚠️ Контекст сессии раздут — этому handoff'у доверять как следующей точке входа
