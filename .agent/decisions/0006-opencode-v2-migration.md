# ADR-0006: OpenCode на sapphira — миграция 1.19 (v1) → 2.0.32 (v2)

**Статус:** accepted (деплой выполнен 2026-10-21 на sapphira; herdr-вопрос закрыт —
интеграцию opencode не ставим, см. «Herdr и v2»)

**Дата:** 2026-10-21

**Контекст.**

sapphira гонял OpenCode **1.19.0** (`pkgs.opencode` из nixos-unstable) как
systemd user-сервис `opencode-web`: `opencode serve --hostname 0.0.0.0 --cors
https://opencode.zeroq.su`, пароль через sops (`secrets/opencode.env` →
`~/.config/opencode/server.env`), cgroup-защита
`MemoryHigh=1G/MemoryMax=2G/OOMScoreAdjust=-900/OOMPolicy=continue`
(`home/modules/opencode.nix`). nginx-vhost `opencode.zeroq.su` проксирует на
`127.0.0.1:4096`. Плагин — `oh-my-openagent@latest`, его конфиг
`~/.omo/omo.jsonc` (11 агентов + 8 категорий, ключ `variant`, `fallback_models`).

Рабочая машина (vetymae, Windows) уже на **v2** (`scoop`, 2.0.32 → 2.1.2 в
ночь 2026-10-21) с плагином `oh-my-opencode-slim@3.0.5`.

Вопрос: можно ли повторить конфигурацию рабочей машины на сервере.

**Что выяснено (проверено, 2026-10-20/21).**

1. **Пакет.** `nixos-unstable` → `opencode 1.19.0`. **v2 есть только в
   nixpkgs master**: `pkgs/by-name/op/opencode/package.nix`, `version =
   "2.0.32"`, `hash = sha256-KATNzF7z3PoUo30KC13Gm8uC6HA2a9bmJCZRfqY5D44=`,
   `OPENCODE_CHANNEL=latest`, `passthru.jsonschema = { cli, config, theme }`
   (**`tui` удалён**), ставит `share/{cli,config,theme}.json`, wrap-ит
   `ripgrep` в PATH, `OPENCODE_DISABLE_AUTOUPDATE=true`.
   PR [NixOS/nixpkgs#569770](https://github.com/NixOS/nixpkgs/pull/569770)
   («opencode, opencode-desktop: 1.19.0 -> 2.0.32») влит в master
   2026-10-19T23:35Z. У v2 **нет GitHub-релизов** (только теги) → «скачать
   tarball и положить в nix» невозможно; npm-путь — `@opencode/cli@2.1.2` +
   `@opencode/cli-linux-x64` (213 MB, bun-ELF).
2. **home-manager `programs.opencode` — v1-only.** Модуль (master, 2026-10-10)
   пишет `opencode.json` + `tui.json`, документирует ключ `plugin` (ед.ч.),
   интегрирует MCP как плоскую карту `settings.mcp`, а `validateFiles.tui`
   берёт `passthru.jsonschema.tui` — **которого в v2-пакете нет** ⇒ сборка
   HM с v2-пакетом и включённой валидацией падает. v2-поддержка в HM не
   влита (issue HM#10070 закрыт как «сделано», но PR от delafthi только в
   работе).
3. **Схема конфига v2** (извлечено из самого бинаря v2): глобальный конфиг
   `~/.config/opencode/{config.json,opencode.json,opencode.jsonc}` (приоритет
   последнего существующего); `plugin` → **`plugins`**; `mcp` → **`mcp.servers`**
   (у записи есть `type`); `tui.json` → **`cli.json`**
   (`$schema: https://opencode.ai/v2/cli.json`, миграция tui.json→cli.json
   автоматическая, но на HM-хосте `tui.json` — read-only симлинк в
   /nix/store ⇒ миграция не может записать ⇒ `cli.json` объявляется явно).
   `reasoning`/`variant` живут в схеме модели, не в ключах opencode.json.
4. **CLI v2.** `opencode web` **удалён**; `opencode serve` отдаёт и API, и
   web-UI (проверено: `GET /` → 200 HTML, `GET /api/health` без кредов → 401
   `UnauthorizedError`). Появились `opencode service start|stop|status`,
   `opencode plugin add|list|check|update`, `opencode mcp add|list`,
   `opencode reload`, `opencode pair` (one-time link для браузера),
   `opencode debug paths|config|agents`. **Дефолтный порт `serve` — 4097**
   (4096 зарезервирован под фоновый сервис v2) — проверено локально:
   `opencode serve --hostname 127.0.0.1` → `server listening on
   http://127.0.0.1:4097`.
5. **Аутентификация не изменилась:** `OPENCODE_PASSWORD`, иначе
   `OPENCODE_SERVER_PASSWORD`, иначе — случайный 32-байтный пароль (тогда
   клиенты не подключатся). HTTP basic, пользователь `opencode`.
6. **Плагины.** v2 ставит npm-пакеты сам (встроенный `@npmcli/arborist`),
   в `~/.cache/opencode/npm/<pkg>/<gen>/node_modules`; `bun`/`npx` для этого
   не нужны, нужны writable HOME + сеть. **v2-совместим только
   `oh-my-opencode-slim`**: в пакете 3.0.5 есть `dist/tui2.js` и
   `dist/v2/tui.d.ts` + документ «OpenCode v2 Compatibility» с baseline
   v2.0.x. `oh-my-openagent` **5.1.40** (latest на 2026-10-20) экспортирует
   только `.`, `./server`, `./tui`, `./schema.json` — **v2-точки входа нет**.
   Конфиг slim-плагина — `~/.config/opencode/oh-my-opencode-slim.json`
   (не `~/.omo/omo.jsonc`, который читает openagent).
7. **Реестр моделей** (`opencode models`, оба хоста): ровно
   `minimax-coding-plan/MiniMax-M3` (variants: none, thinking),
   `minimax-coding-plan/MiniMax-M3.1-Flash` (без variants),
   `opencode/big-pickle` (без variants),
   `opencode/minimax-m3.1-flash-free` (variants: low…max).
   `MiniMax-M3.1-Flash-Preview`, `MiniMax-M2.7-highspeed`,
   `MiniMax-M2.5-highspeed` — **в реестре отсутствуют**. Старый
   `~/.omo/omo.jsonc` на сервере ссылался на `MiniMax-M3.1-Flash-Preview`
   везде — тот же класс грабли, что `kimi-for-coding` (см. R1.x): модель в
   конфиге есть, в реестре — нет.

**Решение.**

1. **Пакет:** `programs.opencode.package = (import inputs.nixpkgs-master {
   system = ...; }).opencode` — тот же input уже был в флейке (его использует
   `modules/server/nextcloud.nix`). `flake.lock` обновлён на rev
   `c4f353ac4a4179840c3f196a33b02053958a3f1d` (2026-10-21).
   Когда v2 попадёт в nixos-unstable — вернуть `pkgs.opencode` и убрать
   зависимость от master.
2. **Конфиг пишется вручную** (`xdg.configFile`), а не через
   `programs.opencode.settings`: HM-модуль v1-only, а нам нужны v2-ключи.
   `programs.opencode` остаётся включённым (он даёт бинарь, wrapper с
   `extraPackages` и systemd-юнит), но `settings`/`tui` у него пустые.
   Файлы:
   - `opencode.json` — `plugins` (мн. ч.) + `mcp.servers`;
   - `cli.json` — `$schema: https://opencode.ai/v2/cli.json` + `plugins`;
   - `oh-my-opencode-slim.json` — 5 агентов (orchestrator/explorer/oracle/
     designer/fixer) на `minimax-coding-plan/MiniMax-M3.1-Flash` — копия
     конфига рабочей машины;
   - `service.json` — `{"disabled": true}`.
3. **Плагин:** `oh-my-opencode-slim@3.0.5` (версия зафиксирована; v2
   обновляет только незапиненные спеки). `~/.omo/omo.jsonc` сохранён как
   legacy-конфиг openagent, но переведён на **существующие** model id.
4. **Порт запинен явно:** `web.extraArgs = [ "--hostname" "0.0.0.0" "--port"
   "4096" "--cors" "https://opencode.zeroq.su" ]` — иначе nginx получит 502.
5. **Фоновый сервис v2 выключен** (`service.json: disabled`), CLI ходит в
   работающий юнит через обёртку `oc` = `opencode --server
   http://127.0.0.1:4096`. Иначе CLI поднимает второй сервер на 4096 —
   конфликт порта + два писателя в один `opencode.db`.
6. **cgroup-ограничения сохранены** без изменений (`Service`, не
   `serviceConfig` — R2).

**Альтернативы и почему не выбраны.**

- **Ждать nixos-unstable.** Чище всего, но контроля версии нет и срок
  неизвестен. Выбрано как следующий шаг после деплоя.
- **Отдельный input `github:anomalyco/opencode/v2.0.32`.** Пинит точную
  версию upstream, но дублирует nixpkgs-пакет и тянет свой build.
- **FOD `@opencode/cli-linux-x64` из npm.** Без сборки, но ~200 MB в store,
  нет схем и нет фиксов nixpkgs. Не взято.
- **Оставить 1.19.** Ноль риска, но не «как на текущем хосте» и без v2-фич.
- **Оставить `oh-my-openagent`.** Под v2 он не имеет точки входа ⇒ не
  вариант (это и есть причина смены плагина на slim).

**Последствия.**

- **Позитивные:** версия сервера совпадает с рабочей машиной (2.0.32);
  конфиг сервера — копия рабочего; `opencode web`-эквивалент (`serve`)
  отдаёт web-UI; `opencode pair` даёт удобный one-time link.
- **Негативные / риски:**
  - **Функциональный даунгрейд оркестрации.** openagent давал 11 агентов и 8
    категорий с роутингом; slim даёт 5 агентов без категорий. Если
    понадобится полный набор — ждём v2-совместимый openagent.
  - **Сборка v2 идёт из исходников (bun)** — тяжёлая. Деплой через
    deploy-rs собирает на целевом хосте: sapphira (5.6 GiB RAM, ~1.8 GiB
    доступно) может уйти в OOM ⇒ собирать на другой машине и доставлять
    замыкание store, либо поднимать сборку на `otreca`/`wsl`.
  - **Зависимость от `nixpkgs-master`** (moving target): следующий
    `nix flake update nixpkgs-master` притащит и другие master-пакеты.
  - **Рост БД:** `~/.local/share/opencode/opencode.db` (SQLite) — на рабочей
    машине уже 9.5 GB. На sapphira `/` свободно 14 GB ⇒ держать в голове
    перенос `XDG_DATA_HOME` на `/mnt/services`.
  - **herdr на sapphira** спавнит `opencode serve` на воркспейс — в v2 это
    отдельный сервер на каждый воркспейс при общей `opencode.db`. Не
    проверено; при деплое — проверить (или перевести herdr на общий сервис).
  - **Два «opencode» на хосте:** фоновый сервис v2 отключён — CLI без
    `--server`/`oc` поднимет приватный stdio-сервер (виден в логе:
    `spawning process … serve --stdio --port 0`). Это не конфликтует по
    порту, но пишет в ту же БД.

**Проверка (выполнена 2026-10-21, деплой — нет).**

- `nix eval` на otreca (копия флейка в /tmp, без изменений на хостах):
  `…programs.opencode.package.version` → `2.0.32`;
  `xdg.configFile."opencode/opencode.json".source` → v2-форма
  (`plugins`, `mcp.servers`); `cli.json`, `oh-my-opencode-slim.json`,
  `service.json` — как задумано; `systemd.user.services.opencode-web` →
  `EnvironmentFile=/home/oqyude/.config/opencode/server.env`,
  `MemoryHigh=1G`, `MemoryMax=2G`, `OOMPolicy=continue`,
  `OOMScoreAdjust=-900`, `ExecStart=…opencode-web-launcher`.
- Настоящий бинарь v2 (рабочая машина, изолированные `XDG_*`): наш
  `opencode.json` распознан (`opencode debug config` показывает
  `plugins` + `mcp.servers`), плагин **установлен** и виден в
  `opencode plugin list` (`oh-my-opencode-slim 3.0.5`).
- На рабочей машине `opencode debug agents` показывает 5 агентов slim-плагина
  (designer/explorer/fixer/oracle/orchestrator) ⇒ конфиг slim-плагина
  читается из `~/.config/opencode/oh-my-opencode-slim.json`.
- Порты и auth проверены на живом бинаре v2 (401 без кредов, 200 HTML на `/`).
- **Не проверено на момент написания раздела (проверено позже, в «Что фактически
  работает»):** полная сборка `nixosConfigurations.sapphira` (нужен ресурс на
  сборку v2 из bun) и фактический рестарт `opencode-web` на sapphira.

**Что осталось за владельцем.**

- ~~Деплой~~ — **выполнен 2026-10-21**: сборка и `nixos-rebuild switch` на
  sapphira (из `/etc/nixos`, рабочее дерево, без коммита в gitea).
- Место сборки v2 (bun) — решено: **на самой sapphira** (5.6 GiB RAM,
  ~1.8–3.1 GiB доступно; пик — `bun --bun ./script/build.ts` ~780 МБ RSS,
  OOM-kill'ов не было, zram заполнялся). Сборка ~25 мин.
- Перенос `XDG_DATA_HOME` → `/mnt/services` — **решено владельцем: отдельная
  задача T37** (БД сейчас `~/.local/share/opencode`, 408 МБ, бэкап pre-v2 снят в
  `/mnt/services/opencode-backup/pre-v2-2026-10-21`; на sapphira `/` свободно
  **9.8 G** из 55 G, на `/mnt/services` — 303 G). Главный риск задачи: гвард
  монтирования мёртв (T4/ADR-0004) ⇒ при не смонтированном `/mnt/services`
  opencode молча создаст новую пустую БД.
- Herdr — проверен, см. «Herdr и v2» ниже.
- ~~Решить, нужен ли herdr-интеграционный плагин для v2 (конфликт с
  read-only `cli.json`)~~ — **решено 2026-10-21: не ставим** (на хосте нет ни
  одной agent-интеграции herdr, а регистрация в `cli.json` всё равно упёрлась
  бы в read-only симлинк) ⇒ владельцу решать нечего.

---

## Инцидент 1: плагин не ставится сам (найдено на деплое)

v2.0.32 **не устанавливает пакеты плагинов при старте сервера** — сервер
загружает только то, что уже лежит в `~/.cache/opencode/npm`. На свежем хосте
(или после очистки кэша) получается ровно то, что выглядит как «всё настроено,
а плагина нет»:

- `opencode plugin list` → «No plugins found»;
- агентов slim-плагина нет, его MCP-серверы (context7, gh_grep) не появляются;
- **в логах нет ни строки об ошибке** — тишина.

Проверено на sapphira 2026-10-21: после первого старта кэш
`~/.cache/opencode/npm` был пуст; `opencode plugin add oh-my-opencode-slim@3.0.5`
(«already configured» + install) его наполнил, и после рестарта юнита плагин
загрузился. Фикс — в `home.activation.installOpencodePlugin` (идемпотентно,
ошибки глушатся).

## Инцидент 2: `webpage` MCP — ENOTEMPTY / Request timed out

MCP поднимается как `npx -y -p webpage-mcp@latest webpage-mcp-stdio`. Две
проблемы, обе из-за кэша `~/.npm/_npx`, который Nix не управляет:

1. **ENOTEMPTY** — `npm` не смог переименовать распакованный каталог
   (остался от v1-эпохи, где тем же MCP пользовался v1-opencode).
   Лечится удалением `~/.npm/_npx/<hash>`.
2. **Request timed out** — первый запуск качает и распаковывает ~200 МБ, а
   MCP-handshake не ждёт столько. Симптом: `/api/mcp` → `webpage: failed`.
   Лечится прогревом кэша → `home.activation.warmWebpageMcp`
   (`npx -y -p webpage-mcp@latest true`).

После обоих фиксов: `context7 connected`, `gh_grep connected`,
`webpage connected`.

## Инцидент 3: `oc` (CLI к работающему серверу)

- `--server` принимается **после** подкоманды: `opencode <cmd> --server <url>`;
  форма `opencode --server <url> <cmd>` парсером v2 не принимается.
- CLI ходит к серверу по HTTP basic → **пароль обязателен**: обёртка читает
  `OPENCODE_SERVER_PASSWORD` (и `OPENCODE_SERVER_USERNAME`, `GEMINI_API_KEY`)
  из того же sops-файла `~/.config/opencode/server.env`, что и юнит.
- Часть подкоманд (`mcp list`, `session list`) с `--server` печатает help —
  фича v2.0.32, не регрессия.
- **`--server` принимают не все подкоманды** (проверено на живом бинаре
  2026-10-21, `opencode <cmd> --help`): `run`, `attach`, `tui`, `api`,
  `models`, `agent` — берут; `mcp`, `service`, `auth`, `serve`, `plugin` —
  **нет** ⇒ `Error: Unrecognized flag: --server in command opencode plugin
  list`. Обёртка `oc` добавляла флаг всем подряд ⇒ локальные команды
  (`plugin list`, `auth`, `service`) падали. Исправлено (коммит `1323982`):
  `oc` фильтрует по подкоманде, уважает явные `--server`/`--standalone` от
  вызывающего, а если сервер на 4096 не поднят — печатает подсказку
  `systemctl --user start opencode-web` вместо connection refused.

## Herdr и v2 (проверено 2026-10-21)

herdr **0.9.3** на sapphira активен (`herdr server --session herdr-prod`).

- **herdr 0.9.3 умеет v2**: по докам herdr.dev/docs/integrations — «supports
  OpenCode V1 `1.18.29` or later and OpenCode V2 (tested with beta `19242`)».
- **Спавнить v2 он может**: PATH сервиса содержит
  `/etc/profiles/per-user/oqyude/bin` → `opencode` резолвится в v2-бинарь;
  `EnvironmentFile` даёт `OPENCODE_SERVER_USERNAME`/`OPENCODE_SERVER_PASSWORD`
  → herdr и его дети видят пароль.
- **Портовой конфликт не возникнет**: herdr поднимает `opencode serve` на
  воркспейс отдельно; в v2 дефолт `serve` — **4097**, а 4096 держит юнит
  `opencode-web` ⇒ в отличие от v1 (дефолт 4096) коллизии нет. Фактический
  спавн воркспейса не проверялся (нужен GUI-сценарий herdr).
- **Интеграция opencode НЕ установлена**: `herdr integration status` →
  `opencode: not installed (~/.config/opencode/plugins/herdr-agent-state.js)`.
  То есть ни lifecycle-reporting, ни native restore для v2 — **это не регрессия
  миграции** (в v1 было так же). Более того, на sapphira не установлена **ни
  одна** agent-интеграция herdr (pi, omp, claude, codex, copilot, devin,
  droid, kimi, opencode, kilo, hermes, qoder, qwen, cursor, mastracode,
  antigravity-cli, grok, letta — все «not installed»), то есть herdr работает
  без них и работал так же в v1.
- **Что именно делает установка** (проверено в песочнице `HOME=/tmp/herdr-test`
  2026-10-21): herdr пишет `~/.config/opencode/plugins/herdr-agent-state.js`,
  `~/.config/opencode/herdr-tui-session.js`,
  `~/.config/opencode/herdr-opencode/tui.js`, `~/.config/opencode/tui.jsonc`
  (эти пути Nix не управляет ⇒ ок) и **регистрирует V2-TUI-плагин в
  `cli.json`** (`plugins` += `./herdr-opencode`).
- **Регистрация в `cli.json` невозможна:** наш `cli.json` — read-only симлинк
  в /nix/store, а herdr отказывается писать в файл с несколькими хардлинками:
  `cannot update /home/oqyude/.config/opencode/cli.json: config has multiple
  hard links; use a separate file or a symlink before retrying` (то есть это
  **не EROFS**, а осознанная проверка herdr). Варианты были: (а) сделать
  `cli.json` writable-файлом (тогда он перестаёт быть Nix-управляемым, и
  herdr дописывает свою регистрацию); (б) не ставить интеграцию (работает
  экранный fallback — детект состояния по скриншоту).
  **Решено: (б)** — ни одной интеграции на хосте нет, ломать
  Nix-управляемость `cli.json` ради одной не нужно. Решение владельца не
  требуется.

## Что фактически работает на sapphira (проверено 2026-10-21)

- `opencode --version` → **v2.0.32**; юнит: `opencode-wrapped-2.0.32 serve
  --hostname 0.0.0.0 --port 4096 --cors https://opencode.zeroq.su`.
- `0.0.0.0:4096` слушает процесс юнита; cgroup: 236 МБ (high 1G, max 2G).
- `GET /` с кредами → 200 HTML, без → 401 на `/api/*`; через nginx
  `https://opencode.zeroq.su/` → 200.
- `/api/agent` → 10 агентов: `orchestrator` (primary) + `explorer`, `oracle`,
  `designer`, `fixer` (subagent) + билтины; модель всех —
  `minimax-coding-plan/MiniMax-M3.1-Flash` ✓.
- `/api/mcp` → context7/gh_grep/webpage — connected.
- LLM smoke: `oc run --agent orchestrator "Ответь ровно одним словом: OK"` →
  «OK»; с явной моделью — `minimax-coding-plan/MiniMax-M3.1-Flash` (платный
  провайдер из sops `auth.json` работает).
- **Ранний вывод «без `--model` CLI показывает free-модель только в заголовке»
  был неверным** (проверено 2026-10-21 по самому сообщению в БД): без явной
  модели CLI v2 выбирает модель сам — `opencode/minimax-m3.1-flash-free`
  (бесплатный тариф opencode) — и отправляет её явно, а она **перебивает**
  модель агента slim-плагина. То есть `oc run --agent orchestrator` реально
  считал на free-модели, хотя `/api/agent` по этому агенту отдавал
  `minimax-coding-plan/MiniMax-M3.1-Flash`. На рабочей машине такого не
  происходит: там TUI помнит последнюю использованную (платную) модель, а на
  сервере БД была пустая. Фикс — глобальный ключ `model` в `opencode.json`
  (схема v2: «Default model to use when no session or agent model is
  selected»).
- Старые сессии v1 читаются (те же `opencode.db`), но в них
  `MiniMax-M3.1-Flash-Preview` — модели, которой **больше нет в реестре**
  (подтверждение, что реестр менялся; см. п. 7 «Что выяснено»).
- **Остановка юнита даёт код 130**: v2-сервер выходит по SIGTERM с
  `status=130`, systemd пишет «Failed with result 'exit-code'». Это **не поломка**:
  `Restart=always` поднимает сервер заново, юнит снова active (проверено на
  рестартах 11:40 и 13:38). В логах выглядит как ошибка — при чтении журнала
  это шум, а не инцидент.
- **Активация сама ставит плагин**: `home.activation.installOpencodePlugin`
  проверен «в лоб» — кэш `~/.cache/opencode/npm/oh-my-opencode-slim@3.0.5`
  удалён вручную, `systemctl --user restart home-manager-oqyude.service` →
  пакет вернулся сам, `opencode plugin list` → `3.0.5`.
- **Legacy `~/.omo/omo.jsonc` валиден по факту, а не по намерению:** на хосте
  развёрнут Nix-управляемый файл, и в нём реальные id реестра
  (`minimax-coding-plan/MiniMax-M3` и `minimax-coding-plan/MiniMax-M3.1-Flash`),
  а не `MiniMax-M3.1-Flash-Preview` (тот остался только в старых сессиях БД).
  Под v2 файл инертен — активен slim-плагин, openagent не загружен.
- **Мёртвый кэш v1 вычищен** (2026-10-21): `~/.cache/opencode/packages`
  (146 M — раскладка v1) и `~/.cache/opencode/npm/oh-my-openagent@latest`
  (146 M — плагин не включён) удалены; активный кэш —
  `~/.cache/opencode/npm/oh-my-opencode-slim@3.0.5` (172 M).
- **`oc` больше не ломает локальные команды** (`plugin list`, `auth`,
  `service`): `--server` добавляется только тем подкомандам, которые его
  принимают (см. «Инцидент 3»).
- **Пароль в `server.env` записан в кавычках** (`OPENCODE_SERVER_PASSWORD="…"`):
  systemd при разборе EnvironmentFile кавычки снимает, а `set -a; . server.env`
  в обёртке `oc` — тоже ⇒ сервер и CLI используют одно значение. Но при
  ручной проверке через `curl -u opencode:$PASS` кавычки надо убрать
  (`… | tr -d '"'`), иначе 401 `UnauthorizedError` — это артефакт проверки, а
  не поломка сервера.
- **`oc models` сразу после рестарта юнита может вернуть
  `ServiceUnavailableError: Location plugins did not finish activating`** —
  сервер ещё поднимает плагины. Через несколько секунд проходит.

## Обновление 2026-10-25

Legacy-конфиг oh-my-openagent удалён из `home/modules/opencode.nix`:
`~/.omo/omo.jsonc` и `~/.config/opencode/oh-my-openagent.json` больше не
объявляются (вместе с блоком `legacyOmoConfig` и ставшим неиспользуемым
`modelStrong`). Единственный конфиг плагина —
`~/.config/opencode/oh-my-opencode-slim.json`.

Плагин oh-my-openagent не ставится и не совместим с v2 — путь возврата на
openagent закрыт: держать его конфиг «на всякий случай» было смысла только
до появления v2-совместимого slim-плагина.

Симлинки/файлы, оставшиеся на диске от прошлой генерации home-manager,
после ближайшей активации надо снести вручную:
`~/.omo/omo.jsonc`, `~/.config/opencode/oh-my-openagent.json`.
