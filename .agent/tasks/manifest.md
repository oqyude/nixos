# Task Manifest — реестр задач техдолга (T38+)

**Session:** techdebt-audit-2026-10-23
**Goal:** read-only аудит техдолга репозитория `nixos`, фиксация метасостояния и
поэтапное снятие долга без изменения публичного поведения.
**Date:** 2026-10-23

> **Этот файл — не копия `tasks/manifest.json`.**
> `tasks/manifest.json` остаётся **машинным источником истины** по задачам T1–T37
> (его формат задан `.agent/src/TEMPLATES/schemas/task-manifest-schema.json`).
> Этот файл — **человекочитаемый реестр новой серии T38+**, порождённой
> read-only аудитом 2026-10-23. Он намеренно не дублирует JSON: ранее
> `manifest.md` был удалён именно как дубликат (`project-state.md`, раздел
> «Дрейф доков устранён», 2026-10-15) — повторение этой ошибки привело бы к
> новому дрейфу.
>
> **Синхронизация:** задачи T38+ в `tasks/manifest.json` **не внесены** —
> правка `.agent/tasks/manifest.json` в этой сессии была запрещена ограничением
> «не трогать файлы под `.agent/` кроме перечисленных». Их регистрация в JSON —
> отдельная авторизованная задача (см. T57).

---

## Task Overview

| ID | Title | Type | Depends On | Status |
|---|---|---|---|---|
| T38 | Живой `herdr_web_token` закоммичен в git открытым текстом | дрейф | — | **частично** — `d76cbc3` |
| T39 | CI не выполняется ни разу: 3 независимых дефекта | хрупкость | — | **done** — `ca450f1`, `db3cbd0`, `0297254` |
| T40 | Check #7 (sops path_regex) не покрывает `modules/*/secrets/` | хрупкость | T39 | **done** — `95a4f92` (параллельная сессия) |
| T41 | Мёртвый код: мёртвые/неиспользуемые модули | мусор | — | **done** — `1b188fb`, `13e90d0` + `2991164` |
| T42 | Комментарии в живом коде противоречат коду | дрейф | — | **done** — `39e1887` (параллельная сессия) |
| T43 | `.ci/checks.sh` + `.pre-commit-config.yaml`: протухший whitelist, неверное имя хелпера | дрейф | — | **done** — `3fb1f3c` |
| T44 | `AGENTS.md`: битые пути и протухшие номера строк | дрейф | — | **done** — `8c86466` |
| T45 | `modules/wsl/nix-serve.nix` — байт-в-байт копия серверного модуля | реструктуризация | — | **done** — `0d52f20` |
| T46 | `options.pxe-infra` (351 стр.) живёт в `modules/options.nix` вместо `modules/pxe-infra/` | реструктуризация | — | **done** — `1adf6dd` |
| T47 | `home/termux.nix` вставляет тело `home/minimal.nix` вместо импорта (78/146 строк) | реструктуризация | — | blocked — нужна проверка merge-семантики HM |
| T48 | Скрипты верификации T3/T4 существуют только в `.temp/`; `.gitignore:4` без якорей | мусор | — | **done** — `2ed525b` |
| T49 | `home/primary.nix:35-69` и `home/secondary.nix:32-66` — идентичный хвост (0 отличий) | реструктуризация | — | blocked — нужна проверка merge-семантики HM |
| T50 | Реестр хостов и адресов отсутствует: 42+5+2 хардкода IP | реструктуризация | T46 | blocked — нужен `nix flake check` |
| T51 | `modules/server/nginx.nix` (515 стр.): данные, дубли и магические порты | реструктуризация | T41 | blocked — нужен снимок `nginx -T` |
| T52 | T4: guard монтирования мёртв на 13 юнитах / 12 сервисах | хрупкость | T39 | blocked — меняет рантайм 12 сервисов |
| T53 | Осиротевшие sops-файлы и судьба `archive/` | мусор | — | blocked — секреты + решение владельца |
| T54 | Мёртвый flake-инпут `proxy-suite` (+ `nix-minecraft` только для архива) | мусор | T41 | blocked — нужен `nix flake lock` |
| T55 | Секреты в 5 корнях (18 файлов) вместо одного | реструктуризация | — | blocked — секреты |
| T56 | `home/modules/opencode.nix` (475 стр., 7 концернов) — монолит | реструктуризация | — | blocked — общий `let`-блок, нужен `nix` |
| T57 | Метаданные `.agent` не соответствуют своим же JSON-схемам; T38+ не внесены в JSON | дрейф | — | blocked — правка `.agent/*.json` вне мандата |

**Всего в серии:** 20 задач · **done 10 (1 частично)** · blocked 10

### Отдельная находка сессии (не входила в план)

**HEAD содержал невалидный Nix.** `modules/server/default.nix:79` и
`modules/vds/default.nix:40` вызывали `config.modules."3x-ui".reconfig`, но
`config` не был объявлен в списке аргументов модуля (`{ lib, pkgs, xlib, … }`
и `{ lib, xlib, … }`), то есть `sapphira` и `otrecа` не должны были
вычисляться. Исправлено в `39e1887` (параллельная сессия добавила `config,`).
Это подтверждает, что `nix flake check` в CI никогда не выполнялся: он бы
это поймал.


> **Определения «риск» и «польза»:** *риск* — вероятность сломать прод или
> рабочее состояние при исправлении; *польза* — сколько долга снимается.
> «Можно сразу» = пункт не меняет публичное поведение, откатывается одним
> `git revert` и проверяем без `nix` (статический тест).

---

## Task Details

### T38: Живой `herdr_web_token` закоммичен в git открытым текстом

**Type:** дрейф
**Где:**
- `.agent/handoff-summary.md:52` — `HERDR_WEB_TOKEN=<64 hex>` в тексте сессии
- `.agent/tasks/manifest.json:412` — тот же литерал (совпадает по SHA-256)

**Суть:** 256-битный токен, единственный гейт для `herdr.zeroq.su`
(vhost без authelia — R1.15 / ADR-0005), лежит в git в открытом виде.
В живом коде токена нет: `modules/server/nginx.nix` содержит 0 hex-литералов
длиной 64 — только описание в комментариях (`:293-296`, `:314-320`).
На хосте токен лежит в
`~/.config/herdr/plugins/config/devswha/herdr-web-ui/env` (mode 0600).

**Риск:** низкий (правка текста) / высокий (без ротации токен остаётся действительным)
**Польза:** высокая
**Можно сразу:** да — но **частично**: `manifest.json` под `.agent/` в этой
сессии трогать запрещено → правка только `handoff-summary.md`; `manifest.json:412`
требует отдельного разрешения.

**Acceptance Criteria:**
- [ ] В `.agent/handoff-summary.md` литерал заменён на `<REDACTED>` + ссылка на путь на хосте
- [ ] `grep -rE '[0-9a-fA-F]{64}' .agent/handoff-summary.md .agent/tasks/manifest.json` → не более 2 совпадений (sha-1 коммитов допустимы)
- [ ] Отмечено, что ротация токена на хосте — отдельная операция (меняет поведение)

---

### T39: CI не выполняется ни разу — 3 независимых дефекта

**Type:** хрупкость
**Где:**
- `.ci/checks.sh` — режим `100644` (`git ls-files -s`), shebang есть
- `.pre-commit-config.yaml:10-11` — `entry: .ci/checks.sh --no-build`, `language: script` → execve без оболочки
- `.github/workflows/nix-checks.yml:20` — `run: .ci/checks.sh` → execve
- `.github/workflows/nix-checks.yml:23-28` — каждая строка `… --dry-run \|\| true`
- `.gitea/workflows/test-runner.yml` — единственный workflow в `.gitea/`, `checks.sh` **не вызывает**

**Суть:** remote только `gitea@git.zeroq.su:oqyude/nixos.git` — GitHub-remote
отсутствует, значит `.github/workflows/` не запускается никогда; в `.gitea/`
лежит workflow, который проверок не делает. Итог: **ни одна из трёх
реализованных проверок не выполнялась ни разу**, а шаги сборки физически не
могут упасть (`|| true` + `--dry-run`).

**Риск:** низкий
**Польза:** высокая — это страховка для всех остальных пунктов
**Можно сразу:** да

**Acceptance Criteria:**
- [ ] `git ls-files -s .ci/checks.sh` → `100755`, **или** оба вызова переписаны на `bash .ci/checks.sh`
- [ ] Workflow лежит в `.gitea/workflows/` (иначе Gitea его не увидит)
- [ ] Есть коммит с красным CI → после починки зелёный (шаг сборки перестаёт быть `\|\| true`)
- [ ] Уникальный файл с битом в репозитории — `modules/pxe-infra/report-sink.py`

---

### T40: Check #7 не покрывает `modules/*/secrets/`

**Type:** хрупкость
**Где:** `.ci/checks.sh:74-95`; сканирование — `:87` (`find secrets -type f`); матчинг — `:84` (`grep -Eqx`)

**Суть:** проверка «sops-файлы соответствуют `path_regex`» видит 5 файлов из 18.
Остальные 13 живут в `modules/{server,containers,essentials,wsl}/secrets/`.
Регекс в `.sops.yaml:4` покрывает их (sops ищет по подстроке), но **проверка
использует `grep -Eqx`** — whole-line — и при расширении области даст
false positive на `modules/server/secrets/authelia.yaml`.

**Риск:** низкий
**Польза:** средняя
**Можно сразу:** да (после T39 — иначе падать будет некому)

**Acceptance Criteria:**
- [ ] Область сканирования — все 18 sops-файлов
- [ ] Матчинг приведён к семантике sops (`re.search`), а не `grep -x`
- [ ] Проверка зелёная на текущем дереве

---

### T41: Мёртвый код — 15 модулей вне графа импортов

**Type:** мусор
**Где:**
- `modules/other/` — 7 файлов (`daw.nix`, `musnix.nix`, `virtual.nix`, `wine.nix`, `gaming/aagl.nix`, `gaming/nix-gaming.nix`, `self/fingerprint.nix`); 4 из них ссылаются на flake-инпуты, **закомментированные** в `flake.nix:8,102,103,110` → не вычисляются
- `modules/server/requirements.nix` (87 стр.) — не импортирован; дублирует подмножество пинов из `modules/server/engipy-backend.nix:46-67`, списки **расходятся**
- `modules/containers/remnanode.nix` — не импортирован; его tmpfiles (`:11-13`) дублируются 5-ю живыми модулями
- `modules/containers/remnawave-examples/` (405 стр.) — не импортируется
- `modules/vds/glances.nix` (md5-идентичен `modules/server/glances.nix`), `modules/vds/netbird.nix` — импорты закомментированы (`modules/vds/default.nix:13,14`)
- `modules/wsl/tools/default.nix` — импорт закомментирован (`modules/wsl/default.nix:12`)
- `home/apps/v2rayn.nix` — импорт закомментирован (`home/apps/default.nix:8`)

**Риск:** низкий
**Польза:** средняя-высокая (~700 строк)
**Можно сразу:** да — при условии статической проверки графа импортов

**Acceptance Criteria:**
- [ ] Ни один удалённый файл не достижим из `configurations/`, `modules/`, `home/`, `deploy/`, `devshells/`
- [ ] Статический тест графа импортов зелёный
- [ ] `flake.nix` не ссылается на удалённые модули

---

### T42: Комментарии в живом коде противоречат коду

**Type:** дрейф
**Где:**
- `modules/containers/3x-ui.nix:54` — «Тег образа ЗАПИНЕН (2026-10-20, **R1.16**)» → пин это R1.5; R1.16 — про uTLS-отпечатки
- `modules/containers/3x-ui.nix:74-75` — «порт вне диапазона **14380-15379**» → `basePorts` (`:26-32`) = 2049/2096/8443, ни одного в диапазоне (диапазон — эпоха откатанной БД, R1.12)
- `modules/vds/nginx.nix:11-13` + `modules/vds/default.nix:15-16` — «`pubrayx1.zeroq.su → 127.0.0.1:15380`» → в `map` (`:24-27`) только `default → xray` и `pubray1.zeroq.su → panel`
- `modules/server/default.nix:42-43` — «14 модулей архивировано (13 в …:37-50, 2 в …)» → 13+2=15≠14, фактически 12+3=15, закомментированных импортов 0
- `lib/mkSystem.nix:7` — «`lib/xlib.nix`» → такого файла нет, это каталог `lib/xlib/` (`lib/xlib/default.nix:38`)

**Риск:** низкий (только текст)
**Польза:** средняя
**Можно сразу:** да

**Acceptance Criteria:**
- [ ] Каждый комментарий соответствует текущему коду
- [ ] Поведение Nix не изменилось (diff — только строки комментариев)

---

### T43: `.ci/checks.sh` + `.pre-commit-config.yaml` — протухший whitelist

**Type:** дрейф
**Где:** `.ci/checks.sh:16` (комментарий), `:20` (имя хелпера), `:30-31` (whitelist); `.pre-commit-config.yaml:8`

**Суть:** панель запинена на `v3.10.2` (`modules/containers/3x-ui.nix:62`), но
whitelist всё ещё содержит `ghcr.io/mhsanaei/3x-ui:latest`, а комментарий
утверждает «панель frozen on :latest». Запись мёртвая; комментарий вводит в
заблуждение. Отдельно: описание check #4 называет `mkServiceStorage`, тогда как
гвард на диске — `mkStorageGuard` (`lib/xlib/helpers.nix:180`).

**Риск:** низкий
**Польза:** средняя
**Можно сразу:** да

**Acceptance Criteria:**
- [ ] Whitelist содержит только реально встречающиеся `:latest` (сейчас — 2 образа tape-rotation)
- [ ] Комментарий соответствует коду
- [ ] Check #1 по-прежнему проходит

---

### T44: `AGENTS.md` — битые пути и протухшие номера строк

**Type:** дрейф
**Где:**
- `:100` — `3x-ui.nix:54` → файл `modules/3x-ui.nix` **не существует**; реально `modules/containers/3x-ui.nix:62`
- `:101` — `3x-ui.nix:33-35` → `modules/containers/3x-ui.nix:35`
- `:105` — `opencode.nix:354` → `home/modules/opencode.nix:449`
- `:97` — `server.nix:130` → `configurations/server.nix:129`
- `:78` — `nginx.nix:109,253` → `modules/server/nginx.nix:109` и **:378**
- `:104` — `default.nix:7-44 / комментарий 38-41` → импорты `8-48`, комментарий `42-47`

**Риск:** низкий
**Польза:** средняя — `AGENTS.md` читается агентом всегда, битая ссылка уводит
следующего агента не туда
**Можно сразу:** да

**Acceptance Criteria:**
- [ ] Каждая ссылка `путь:строка` в `AGENTS.md` указывает на существующий файл и верную строку
- [ ] Проверка ссылок зелёная

---

### T45: `modules/wsl/nix-serve.nix` — байт-в-байт копия

**Type:** реструктуризация
**Где:** `modules/wsl/nix-serve.nix` (md5 `0aca1128…` = `modules/server/nix-serve.nix`); импорт — `modules/wsl/default.nix:10`

**Суть:** два идентичных модуля на двух живых хостах. Правка в одной копии не
доезжает до другой. `sopsFile = ./secrets/nix-serve.yaml` разрешается
относительно каталога модуля, поэтому при импорте серверного модуля wsl
получит `modules/server/secrets/nix-serve.yaml` — **содержимое md5-идентично**
(`af6e0441…`), поведение не меняется. Второй sops-файл (`modules/wsl/secrets/nix-serve.yaml`)
станет осиротевшим — **удалять запрещено**, см. T53.

**Риск:** низкий (md5-идентичность доказывает эквивалентность)
**Польза:** средняя
**Можно сразу:** да — со статическим тестом

**Acceptance Criteria:**
- [ ] `modules/wsl/nix-serve.nix` удалён, `modules/wsl/default.nix:10` импортирует `../server/nix-serve.nix`
- [ ] Статический тест подтверждает: ровно один модуль объявляет `services.nix-serve`
- [ ] `modules/server/secrets/nix-serve.yaml` не изменён

---

### T46: `options.pxe-infra` живёт не в том каталоге

**Type:** реструктуризация
**Где:** `modules/options.nix:82-433` — 347 строк из 433 (80%); неймспейс разорван: родитель `options.pxe-infra.bootloader` — `modules/options.nix:382`, ребёнок `options.pxe-infra.bootloader.bypassFallback` — `modules/pxe-infra/default.nix:40`

**Суть:** опция одной фичи лежит в общем файле кросс-модульных опций, хотя у
фичи есть собственный каталог `modules/pxe-infra/` (8 файлов).
`modules/pxe-infra/default.nix:26-33` **уже декларирует именно это намерение**:
«Declared here (not in `modules/options.nix`) because this task's scope is
`modules/pxe-infra/` only». `config.pxe-infra` читается/задаётся только на
mini-laptop (`configurations/mini-laptop.nix:88`), который импортирует
`../modules/pxe-infra` (`:17`).

**Риск:** средний (изменение графа модулей; опция перестаёт существовать на хостах без pxe-infra)
**Польза:** средняя
**Можно сразу:** **нужна страховка** — статический тест + `nix flake check` у владельца (на этой машине `nix` отсутствует)

**Acceptance Criteria:**
- [ ] `options.pxe-infra` объявлен ровно в одном файле, лежащем в `modules/pxe-infra/`
- [ ] `modules/pxe-infra/default.nix` импортирует этот файл
- [ ] Ни один модуль вне `modules/pxe-infra/` не читает `config.pxe-infra`
- [ ] `modules/options.nix` больше не содержит `options.pxe-infra`
- [ ] `nix flake check` проходит (исполнит владелец — `nix` отсутствует на машине агента)

---

### T47: `home/termux.nix` вставляет тело `home/minimal.nix`

**Type:** реструктуризация
**Где:** `home/termux.nix:141-215` — 78 из 146 строк совпадают с `home/minimal.nix`; расхождение — 8 строк (обёртка + `shellWrapperName = "y";` в `:152`)

**Суть:** `termux.nix` копирует тело `minimal.nix` вместо импорта. Плюс
список плагинов yazi существует в трёх местах: `home/minimal.nix:15-31`,
`home/termux.nix:153-169`, `modules/essentials/packages.nix:151-169`.
Сам `home/termux.nix:17-19` признаёт дублирование в комментарии.

**Риск:** средний (home-manager на nix-on-droid; `programs.yazi.plugins` при
двойном определении **конкатенируется** — сливать нельзя, блок надо заменить
импортом целиком)
**Польза:** средняя
**Можно сразу:** **нужна страховка** — статический тест эквивалентности набора
`programs.*` до/после

**Acceptance Criteria:**
- [ ] `home/termux.nix` не содержит копии тела `home/minimal.nix`
- [ ] Набор включаемых `programs.*` до и после совпадает (статический тест)
- [ ] `shellWrapperName = "y"` для termux сохранён

---

### T48: Скрипты верификации T3/T4 — только в `.temp/`; `.gitignore` без якорей

**Type:** мусор
**Где:** `.temp/` — 22 файла (116 KB), вне git; `.gitignore:4` — правило `scripts` без якорей

**Суть:** `.temp/` содержит **единственные** копии скриптов верификации
mount-guard и nftables (`t4-live-test{,v2,v3}.sh`, `t4-final-v{5,6,7,8}.sh`,
`verify-{guard-direct,t4-guard,reality-chain,reality-dest}.sh`,
`cleanup-*.sh`, `deploy-t3-*.sh`). При переустановке рабочей машины они
теряются. Одновременно `.gitignore:4` (`scripts`, без якорей) проглотит любой
будущий каталог `scripts/` **в любом месте** — включая тот, в который эти
скрипты нужно положить.

**Риск:** низкий
**Польза:** средняя
**Можно сразу:** да — **порядок важен**: сначала якорь в `.gitignore`, потом
перенос скриптов

**Acceptance Criteria:**
- [ ] Правило `scripts` в `.gitignore` заякорено (`/scripts/` либо явно перечислены исключения)
- [ ] Каталог с сохранёнными скриптами верификации **не** игнорируется git
- [ ] Содержимое перенесённых скриптов не изменено

---

### T49: Идентичный хвост двух desktop-home

**Type:** реструктуризация
**Где:** `home/primary.nix:35-69` ≡ `home/secondary.nix:32-66` — 63 строки, **0 отличий**; расходятся только `symlinksPaths` (`:9-23` vs `:9-18`) и список импортов (`:30-36` vs `:25-33`)

**Риск:** низкий-средний
**Польза:** средняя
**Можно сразу:** **нужна страховка** — статический тест на совпадение набора опций

**Acceptance Criteria:**
- [ ] Общий хвост вынесен в один модуль
- [ ] Набор опций `home/primary.nix` и `home/secondary.nix` до и после совпадает (статический тест)

---

### T50: Реестр хостов и адресов отсутствует

**Type:** реструктуризация
**Где:** `192.168.1.20` — 42 вхождения в 4 файлах (`modules/server/coredns.nix` — 35, `modules/server/nginx.nix`, `modules/server/nextcloud.nix`, `home/termux.nix`); `100.64.0.0` — 5; `100.64.1.0` — 2. Плюс четыре независимых списка: имена (`configurations/default.nix:13-39`), SSH-алиасы (`home/termux.nix:251-279`), DNS (`modules/server/coredns.nix:12-45`), цели деплоя (`deploy/default.nix:12-14,28-32`)

**Суть:** пути централизованы (`lib/xlib/dirs.nix`, 116 использований в 40
файлах), **адреса — нет**. Это конкретизация бэклог-вопроса 6.6
(`.agent/roadmap/sources.md:81`).

**Риск:** средний-высокий
**Польза:** высокая
**Можно сразу:** **blocked** — требует `nix flake check` и регресса на хостах (`nix` отсутствует на машине агента)

---

### T51: `modules/server/nginx.nix` — 515 строк, данные вперемешку с логикой

**Type:** реструктуризация
**Где:** таблица `sites` (`:37-94`, 11 записей); forward-auth продублирован в `:167-200` и `:229-260` (29 из 34 строк); 4 пары «порт в nginx ↔ порт в модуле сервиса»: `:40`↔`immich.nix:13` (2283), `:76`↔`navidrome.nix:21` (4533), `:81`↔`calibre-web.nix:29` (8083), `:86`↔`nix-serve.nix:13` (5000)

**Риск:** средний (nginx-конфиг — высокоценный актив)
**Польза:** высокая
**Можно сразу:** **blocked** — проверка требует снимка `nginx -T` до/после (нужен живой хост)

---

### T52: T4 — guard монтирования мёртв

**Type:** хрупкость
**Где:** `lib/xlib/helpers.nix:180-189` (хелпер корректен); 12 вызовов через `serviceConfig`: `modules/containers/3x-ui.nix:84`, `modules/containers/tape-rotation.nix:105,114`, `modules/server/{calibre-web:67, gitea:38, homebox:33, immich:26, navidrome:33, nextcloud:214, postgresql:27, samba:76, syncthing:18, uptime-kuma:26}`

**Суть:** `ConditionPathIsMountPoint` — директива `[Unit]`, но через
`serviceConfig` рендерится в `[Service]`, где systemd её не читает.
13 юнитов / 12 сервисов стартуют на пустом bind-mount и создают свежую
пустую БД.

**Риск:** **высокий** (перенос меняет рантайм-поведение 12 сервисов)
**Польза:** высокая
**Можно сразу:** **blocked** — прямо меняет публичное поведение; по условию
задачи такие правки не делаются без явного согласования. Требуется: (1)
падающая проверка в CI, (2) staged rollout (сначала VDS — там
`modules/vds/systemd.nix:19` guard и так пустой), (3) `RequiresMountsFor` **не
добавлять** (R1.2). **T37 зависит от T4** — перенос БД opencode на
`/mnt/services` до починки T4 создаст пустую БД и молча потеряет сессии.

---

### T53: Осиротевшие sops-файлы и судьба `archive/`

**Type:** мусор
**Где:** `modules/containers/secrets/remnawave.yaml`, `modules/server/secrets/ca.json`, `modules/server/secrets/step-ca.yaml`, `modules/essentials/secrets/settings.yaml` (последний — только в закомментированных строках `modules/essentials/settings.nix:107-124`); `archive/` — 15 `.nix` + `kokoro-tts/` (4 файла), вне импортов; `modules/wsl/secrets/nix-serve.yaml` станет осиротевшим после T45

**Риск:** средний
**Польза:** средняя
**Можно сразу:** **blocked** — секреты трогать запрещено; `AGENTS.md:104`
описывает `archive/` как намеренную часть layout, удаление — решение владельца

---

### T54: Мёртвый flake-инпут

**Type:** мусор
**Где:** `flake.nix:76-79` (`proxy-suite`) — 0 ссылок в коде; `flake.nix:88` (`nix-minecraft`) — используется только `archive/server-modules/minecraft.nix:17-18`

**Риск:** средний (меняется `flake.lock`)
**Польза:** низкая-средняя
**Можно сразу:** **blocked** — `nix flake lock` недоступен (нет `nix` на машине агента)

---

### T55: Секреты в 5 корнях

**Type:** реструктуризация
**Где:** `secrets/` (5), `modules/server/secrets/` (8), `modules/containers/secrets/` (3), `modules/essentials/secrets/` (1), `modules/wsl/secrets/` (1) — 18 файлов

**Польза:** высокая (упрощает check #7, `.sops.yaml`, делает осиротевшие заметными)
**Можно сразу:** **blocked** — секреты запрещены к правке; есть bootstrap-цикл (`AGENTS.md`, раздел «Где НЕ лезть»)

---

### T56: `home/modules/opencode.nix` — 475 строк, 7 концернов

**Type:** реструктуризация
**Где:** `programs.opencode` (`:183`), `xdg.configFile` ×4 (`:240,247,255,278`), activation ×2 (`:364,379`), `programs.opencode.web` (`:398`), `systemd.user.services` (`:449`), activation (`:466`)

**Риск:** низкий-средний
**Польза:** средняя
**Можно сразу:** **нужна страховка** — статический тест на сохранение набора опций

---

### T57: Метаданные `.agent` не соответствуют своим схемам; T38+ не внесены в JSON

**Type:** дрейф
**Где:**
- валидатор схем отсутствует (`grep jsonschema|check-jsonschema|ajv` → 0 совпадений)
- `.agent/tasks/manifest.json` — нет обязательного `version`, 8 лишних верхнеуровневых ключей, **28 из 35** задач имеют `type` вне enum
- `.agent/checkpoints.json` — 8 лишних ключей
- `.agent/decisions/index.json` — лишний `proposals`
- `.agent/src/TEMPLATES/request.json:2` — **висячая** `$schema` → `schemas/request-schema.json` не существует
- `.agent/src/COMMANDS/invariant-tests.md:25-42` определяет тип `"test"` / `T-INV-NNN` — таких задач **ноль**, команда никогда не запускалась

**Риск:** низкий
**Польза:** средняя
**Можно сразу:** **blocked** — починка артефактов требует правки `.agent/tasks/manifest.json` и `.agent/checkpoints.json`, которые в этой сессии трогать запрещено. Валидатор, который сразу падает, ломает CI (T39) — сначала артефакты, потом валидатор.

---

## Связи и порядок

```
T39 (CI) ──► T40 (check #7) ──► T42/T43/T44/T48 (дрейф, мусор)
T41 (мусор) ──► T51 (nginx) ──► T50 (реестр хостов)
T45 (nix-serve) ──► T53 (осиротевший wsl-секрет)
T46 (options.pxe-infra) ──► T50
T52 (T4) ──► T37 (перенос БД opencode)  ← T37 в manifest.json, не в этой серии
```

**Правило:** каждый пункт — один коммит, откатывается через `git revert`.
Пункты «нужна страховка» выполняются только после того, как их статический
тест написан и проходит **до** правки.
