# Project State
# Auto-generated — updated by ANALYSE (initial) and METASTATE (on updates)

**Last updated:** 2026-10-23
**Session:** techdebt-audit-2026-10-23

## Session techdebt-audit-2026-10-23 — аудит техдолга

### Что было

Read-only аудит репозитория на техдолг: 233 tracked-файла, 147 `.nix`
(132 живых + 15 в `archive/`), 11 165 строк живого Nix, 18 sops-файлов в
5 каталогах. Разбирались шесть направлений: структура и вложенность,
монолиты и дубли, дрейф документации ↔ кода, хрупкие решения, тестовое
покрытие, мусор. Код на этом шаге **не менялся** — только чтение, `grep`,
`git log/status/ls-files/diff/md5sum`.

### Что сделано

1. **Зафиксировано метасостояние** (этот файл, `.agent/tasks/manifest.md`
   — создан заново, `.agent/handoff-summary.md`).
2. **Реестр задач T38+** — 20 пунктов (11 pending, 9 blocked) в
   `.agent/tasks/manifest.md`: для каждого ID, суть, `путь:строка`, тип
   (реструктуризация / дрейф / мусор / хрупкость), риск, польза, «можно
   сразу или нужна страховка».
3. **Сняты протухшие утверждения** в этом файле: `3x-ui` запинена на
   `v3.10.2` (не `:latest`), T18/gitea-runner закоммичен, ADR-0003 и
   ADR-0005/0006 в таблице решений, тестовый статус, счётчик
   `192.168.1.20` = 42, ссылка `nginx.nix:253` → `:378`.

### Что дальше

**Порядок работ** (каждый пункт — отдельный, откатываемый коммит):

| Шаг | Задачи | Суть |
|---|---|---|
| 1 | T38 | убрать литерал `herdr_web_token` из git |
| 2 | T39, T40 | починить CI (3 дефекта) и расширить check #7 на `modules/*/secrets/` |
| 3 | T41, T48 | удалить мёртвые модули; спасти скрипты верификации T3/T4 из `.temp/`; заякорить `.gitignore` |
| 4 | T42, T43, T44 | дрейф в комментариях, в CI-конфиге, в `AGENTS.md` |
| 5 | T45 | дедупликация `modules/wsl/nix-serve.nix` |
| 6 | T46, T47, T49, T56 | реструктуризация — **только после страховочного теста** |

**Заблокировано и ждёт решения владельца:** T50 (реестр хостов — нужен
`nix flake check` и регресс на хостах), T51 (nginx — нужен снимок
`nginx -T`), T52 (T4 — меняет рантайм-поведение 12 сервисов), T53
(секреты и `archive/`), T54 (`nix flake lock`), T55 (секреты), T57
(починка артефактов `.agent` под свои схемы).

**Ограничение этой сессии:** на машине агента **нет `nix`** — сборку и
`nix eval` выполнить нельзя. Поэтому функциональные правки выполняются
только под статическими тестами, а всё, что требует `nix`, помечено
blocked.

## Project Type

`existing` — NixOS-конфиг домашнего флота. 7 host-outputs (6 NixOS + 1 nix-on-droid).

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Nix |
| Framework | NixOS modules + home-manager |
| Database | PostgreSQL (sapphira), sqlite (3x-ui) |
| Test runner | нет юнит-тестов; `.ci/checks.sh` (3 проверки) + 3 CI-файла — но **ни одна проверка ни разу не выполнялась** (см. T39) |
| Package manager | Nix (flakes) |
| Linter/formatter | none |

## Current Architecture

Модульный монолит с xlib-инъекцией. `flake.nix` → `nixosConfigurations.<attr>` через `configurations/default.nix`. Каждый хост получает `xlib` (identity + dirs + helpers) через `specialArgs` в `lib/mkSystem.nix`. `modules/default.nix` импортирует `nixosModules.default` (все NixOS) или `nixosModules.strict` (только nix-on-droid).

```
configurations/  → 7 хостов (default, atoridu, rydiwo, otreca, sapphira, wsl, epral)
modules/         → essentials + per-type (desktop/server/vds/wsl/containers/termux)
home/            → home-manager per device-type
lib/xlib/        → чистые данные (devices, dirs, helpers)
deploy/          → deploy-rs ноды: sapphira, otreca, rydiwo
secrets/         → sops, один age-ключ
```

## Key Modules

| Module | Status | Description |
|--------|--------|-------------|
| `configurations/default.nix` | existing | Реестр хостов + `mkXlib` |
| `lib/xlib/default.nix` | existing | `mkXlib` — единственная точка сборки xlib |
| `modules/default.nix` | existing | `defaultModule` (NixOS) + `strictModule` (nix-on-droid) |
| `modules/options.nix` | existing | Кросс-модульные опции `host.builder` / `host."3x-ui"`. **80% файла (347 стр.) — `options.pxe-infra`**, которая по собственному намерению `modules/pxe-infra/default.nix:26-33` должна жить в `modules/pxe-infra/` (см. T46) |
| `modules/users.nix` | existing | Пользователь + sops + hostKey bootstrap |
| `modules/essentials/ssh.nix` | existing | openssh + hostKey |
| `modules/server/{nginx,coredns}.nix` | existing | Reverse proxy + DNS (`zeroq.su`, `home.arpa`) |
| `modules/server/postgresql.nix` | existing | PostgreSQL + `mkStorageGuard` (`lib/xlib/helpers.nix:180-189`; guard сейчас мёртв, см. T4) |
| `modules/server/gitea-runner.nix` | existing | Gitea Actions host-runner на sapphira. **См. ADR-0004**: имя юнита экранировано `escapeSystemdPath`; переопределять только по байт-в-байт совпадающему ключу |
| `modules/server/systemd.nix` | existing | rsync oneshots с `requiresMountsFor` |
| `modules/containers/3x-ui.nix` | pinned | Панель запинена на `v3.10.2` (`modules/containers/3x-ui.nix:62`). Ядро Xray — состояние панели, различается по хостам (R1.5, R1.8) |
| `home/<type>.nix` | existing | Per-type home-manager |
| `home/modules/opencode.nix` | existing | OpenCode CLI + systemd user (см. R2) |
| `deploy/default.nix` | existing | deploy-rs: sapphira, otreca, rydiwo |

## Hosts

| Attr | hostname | device.type | deploy | stateVersion | Примечание |
|---|---|---|---|---|---|
| `default` | nixos | minimal | — | — | Шаблон |
| `atoridu` | atoridu | primary | — (manual) | 26.05 | xanmod, mini-PC, без nixos-hardware |
| `rydiwo` | rydiwo | secondary | deploy-rs | 26.05 | Chuwi MiniBook, NTFS `lamet-drive` (mask=0000); импортирует `nixos-hardware.nixosModules.chuwi-minibook-x` и `../modules/pxe-infra` (`configurations/mini-laptop.nix:14,17`) |
| `otrecа` | otreca | vds | deploy-rs | 25.05 | VPS, Tailscale-only SSH, nftables (нужен A3) |
| `sapphira` | sapphira | server | deploy-rs | 25.05 | Домашний сервер, `firewall.enable = false` намеренно |
| `wsl` | wsl | wsl | — (manual) | 24.11 | WSL на vetymae (Windows 192.168.1.100) |
| `epral` | epral | termux | — | 24.05 | Android nix-on-droid, через `mobile.nix` |

## Services (sapphira, активные)

20+ системных сервисов (число не проверялось поштучно, это нижняя оценка) + **4 контейнера**: `3xui_app` (`modules/containers/3x-ui.nix:53`), `taperotation-backend` и `taperotation-frontend` (`modules/containers/tape-rotation.nix:51,76`), `open-webui` (`modules/containers/open-webui.nix:52`). `modules/containers/remnanode.nix` и `modules/containers/remnawave-examples/` **не импортируются** — вне графа импортов (см. T41). Полный инвентарь в `tasks/manifest.json`. Все потребители `mkStorageGuard` (13 юнитов / 12 сервисов) нуждаются в починке гварда: postgresql, samba, homebox, gitea, navidrome, syncthing, uptime-kuma, immich, nextcloud, calibre-web, 3x-ui (`podman-3xui_app`), tape-rotation (два юнита).

## Network

```
LAN 192.168.1.0/24:
  .20 sapphira  (зашит в 42 места в 4 файлах; см. вопрос 6.6 и T50)
  .1  роутер (gateway)
  .100 vetymae (Windows-хост с WSL)

Tailscale CGNAT 100.64.0.0/10:
  100.64.0.0    = sapphira (назначен вручную, 4 файла / 5 строк:
                   home/termux.nix:256, modules/server/nextcloud.nix:80,
                   modules/server/nginx.nix:109 и :378, modules/vds/systemd.nix:10)
  100.86.62.4   = opencode на vetymae
  100.106.21.39 = miniflux

Internet:
  sapphira: пробросы роутера = 22, 80, 443, 8443 (xray), 22000 (syncthing).
  Эти пробросы нигде не выражены в Nix: `networking.firewall` на sapphira
  намеренно не используется (R1.3), список живёт только на роутере.
```

## Decisions in Effect

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-0001 | sops-пути: `config.sops.secrets.<name>.path` (не литерал) | active |
| ADR-0002 | Бэкапы вне Nix — accepted risk (вопрос 5.6 не отвечен, R1.9) | accepted (2026-10-15) |
| ADR-0003 | Цепочка 3x-ui REALITY на otreca (R1.10–R1.13) | active |
| ADR-0004 | Имя systemd-юнита = `escapeSystemdPath`-форма upstream (R1.14) | active |
| ADR-0005 | herdr-webui без authelia, только herdr token (R1.15) | accepted (2026-10-15) |
| ADR-0006 | Миграция на OpenCode v2 (R1.19) | accepted (2026-10-21) |

Подробнее: `.agent/decisions/0001-sops-secrets-paths.md`,
`.agent/decisions/0002-backups-external.md`,
`.agent/decisions/0003-3x-ui-reality-chain.md`,
`.agent/decisions/0004-systemd-unit-attr-name.md`,
`.agent/decisions/0005-herdr-webui-no-authelia.md`,
`.agent/decisions/0006-opencode-v2-migration.md`.

## Testing Status

Юнит-тестов нет (`grep passthru.tests|runTests|testDerivation` → 0 совпадений).
Есть `.ci/checks.sh` (140 стр.) с 3 реализованными проверками (#2 `nix flake check`,
#7 sops path_regex, #1 нет `:latest`) и 3 CI-файла, **но ни одна проверка ни
разу не выполнялась**: `.ci/checks.sh` в git с режимом `100644` (оба вызова
делают exec), workflow лежит в `.github/workflows/` при единственном
gitea-remote, шаги сборки заканчиваются `|| true` + `--dry-run`.
Не реализованы 4 кандидата (#3 coredns↔nginx, #4 потребители guard'а,
#5 финальная политика nftables, #6 `listen.addr`) — `.ci/checks.sh:18-22`.
Реестр задач по этому — `.agent/tasks/manifest.md` (T39, T40, T52).

## Open Concerns

- **B1 / T4 (severity: high):** гвард на несмонтированный `/mnt/services`
  **не работает ни на одном из 13 юнитов / 12 сервисов**: postgresql, samba,
  homebox, gitea, navidrome, syncthing, uptime-kuma, immich, nextcloud,
  calibre-web, 3x-ui (`podman-3xui_app`), tape-rotation (два юнита:
  `podman-taperotation-backend` и `podman-taperotation-frontend`).
  `ConditionPathIsMountPoint` — директива `[Unit]`, но `mkStorageGuard`
  (`lib/xlib/helpers.nix:180-189`) отдаёт её через `serviceConfig` →
  `[Service]` → systemd игнорирует. Подтверждено построчно в отрендеренных
  юнитах на sapphira (у `gitea` секция `[Service]` начинается со строки 5,
  `ConditionPathIsMountPoint` лежит на строке 14; номера строк зависят от
  состава `[Unit]`, поэтому надёжный признак — само наличие директивы в
  `[Service]`). Мердж при этом не при чём: `serviceConfig` с
  правильным ключом мержится штатно, проблема именно в секции.
  `RequiresMountsFor` в хелпере **нет намеренно** (проверено на sapphira
  2026-10-10): такая зависимость заставит systemd сам монтировать ФС при
  старте юнита и обессмыслит гвард; порядок задаётся через `After=` на
  `.mount`-юнит в самом потребителе.
  Сервисы стартуют на пустой БД. Гвард с gitea-runner снят осознанно — он
  охранял пустое множество (у раннера ноль дескрипторов на внешнем диске),
  но именно поэтому до T4 ничто не разделяет Gitea, стартующий на пустой БД,
  и CI-раннер, который затем погонит по ней job'ы.
- **gitea-runner: фикс закоммичен** (T18 → completed, `tasks/manifest.json`,
  коммиты `9bf9407`/`b62a980`/`d021804`); ADR-0004 принят. Прежняя запись
  «лежит только в рабочем дереве» была протухшей — снята 2026-10-23.
- **A3**: nftables на VDS (`configurations/vds.nix:71-91`, chain `input`, `policy`
  не объявлен) без явной финальной политики — неявный accept.
- **C1–C5**: 3x-ui заморожен; формальный ADR **есть** — ADR-0003 (`accepted`,
  `decisions/index.json:26-31`). Прежняя запись «без формального ADR» была
  протухшей — снята 2026-10-23.
- **2.2/5.5**: `vetymae` / `lamet` / `therima` / `soptur` в `dirs.nix` — природа неясна.
- **4.1/4.2**: root-SSH и bootstrap-цикл ключа — не задокументированы.
- **6.6**: `192.168.1.20` зашит в **42 места в 4 файлах** (в 35 из них —
  `modules/server/coredns.nix`) — рефакторинг отложен, задача T50.
- **Дрейф доков устранён:** дубликат `.agent/tasks/manifest.md` удалён
  2026-10-15 — **но восстановлен 2026-10-23 в новом качестве**: не как
  копия `manifest.json`, а как человекочитаемый реестр серии T38+
  (`.agent/src/PROTOCOLS/07_HANDOFF.md:39` требует наличие обоих файлов).
  Источник истины по T1–T37 — по-прежнему `.agent/tasks/manifest.json`.
- **`nix flake check` в этой сессии локально не доходит до конца:** на
  `nixosConfigurations.sapphira` (5-й из 7 хостов) процесс не отвечает и
  завершается без вывода. T2 в `manifest.json` остаётся `completed` — коммит
  61b3724 фиксирует более ранний прогон владельца; этот завис — локальная
  проблема прогона, не отзыв T2. Причина не расследована (предположительно
  интерференция с локальной сборкой sapphira, на котором идёт сессия, либо
  sops-cycle на `/etc/ssh/id_ed25519`). При следующей ревизии — воспроизвести.

Полный список — в `roadmap/sources.md` (открытые вопросы слоёв 0-11).
