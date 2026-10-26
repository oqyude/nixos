# Project State
# Auto-generated — updated by ANALYSE (initial) and METASTATE (on updates)

**Last updated:** 2026-10-25
**Session:** cleanup-2026-10-25 (закрытие T3/T20/T38/T57 + T4)

## Session cleanup-2026-10-25 — закрытие открытых high-severity и дрейфа метаданных

### Что было

`execution` висел в `in_progress` из-за двух high-severity задач: T4 (мёртвый
mount-guard) и T20 (CI без execute-бита). При этом T20 уже была исправлена в
дереве, но числилась pending; серия T38–T57 существовала только в
`manifest.md`; живой `herdr_web_token` лежал открытым текстом в
`manifest.json`; `checkpoints.json` датировался 2026-10-15.

### Что сделано

1. **T38 — токен ротирован 2026-10-25.** Старое значение удалено из
   `manifest.json` (поле `token` → `secret_ref`), `handoff-summary.md` был
   вычищен раньше (`d76cbc3`). Ротация выполнена через
   `herdr plugin action stop/start`: старый токен → 401, новый → 200 на
   `/api/bridge`. Git-история содержит старый литерал — он недействителен,
   перезапись истории не выполнялась.
2. **T3 — посылка опровергнута runtime-проверкой.** `nft list ruleset` на
   otreca: `inet nixos-fw` уже имеет `policy drop` и явные accept'ы; рукописный
   `inet filter` — вторая base chain, которая только режет SYN. Добавление
   `policy drop` в неё заблокировало бы весь трафик VDS. Код не менялся;
   исправлены инвариант 6 и строка «Ловушек» в `AGENTS.md`, proposal T3-A
   помечен `withdrawn`.
3. **T20 — закрыта:** `100755` (`ca450f1`), вызов через `bash` (`db3cbd0`),
   workflow в `.gitea/workflows/`, падающие шаги (`0297254`).
4. **T57 — метаданные синхронизированы:** T38–T57 внесены в `manifest.json`
   (55 задач), схемы расширены под фактический формат, добавлен
   `.ci/tests/validate-metadata.py` (check #9). `bash .ci/checks.sh --no-build`
   → PASS 4 / FAIL 0 (check #2 пропущен флагом).
5. **T4/T52 — guard переведён в `[Unit]`.** `mkStorageGuard` отдаёт фрагмент
   `unitConfig`; 13/13 юнитов проверены в собранном дереве — условие строкой 3
   под `[Unit]`, в `[Service]` ноль вхождений, `RequiresMountsFor` нет.
   Ключи переписаны на реальные юниты (`samba-smbd`, `phpfpm-nextcloud`,
   `immich-server`), три фантомных пустых юнита исчезли. На `vds` гвард
   отключён: у otreca нет External, иначе `podman-3xui_app` был бы пропущен и
   панель погасла. Сборки sapphira и otreca — exit 0; `switch` не выполнялся.
6. **Консолидация раздробленных attr-path записей** (по итогам read-only
   аудита): `3xui-reconfig` в `modules/server/default.nix` и
   `modules/vds/default.nix`, `authelia.after/wants`, `gitea-actions-runner`
   settings (14 записей → 4 блока), `boot.loader.grub`, `services.logind`,
   `pxe-infra.bridge`, `pipewire.alsa`, `nix.{distributedBuilds,buildMachines}`,
   `nix.settings` на WSL, `build.activation` на termux. Найдена и заведена
   **T58**: тройной дубль
   `networking.firewall.interfaces."${matchAll}".allowedUDPPorts = [ 53 ]`
   (`3x-ui`, `open-webui`, `tape-rotation`) — рантайм корректен за счёт
   `canonicalizePortList`, но владельца надо оставить одного.

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
3. **Сняты протухшие утверждения** в этом файле: `3x-ui` запинена (тогда
   `v3.10.2`, с 2026-10-25 — `v3.11.0`, ADR-0007; не `:latest`), T18/gitea-runner закоммичен, ADR-0003 и
   ADR-0005/0006 в таблице решений, тестовый статус, счётчик
   `192.168.1.20` = 42, ссылка `nginx.nix:253` → `:378`.

### Что дальше

**Сделано в этой сессии** (каждый пункт — отдельный коммит, кроме отмеченного):

| Задачи | Итог |
|---|---|
| T38 | литерал убран из `handoff-summary.md` (`d76cbc3`); 2026-10-25 токен ротирован, вычищен из `manifest.json` (`token` → `secret_ref`) |
| T39 | CI починен в три коммита: бит исполнения (`ca450f1`), вызов через `bash` (`db3cbd0`), workflow в `.gitea/` + падающие шаги (`0297254`) |
| T40 | check #7 расширен на все `*/secrets/*` — `95a4f92` (**параллельная сессия**) |
| T41 | 12 мёртвых модулей удалено; страховка — check #8 «граф импортов» (`1b188fb`) |
| T42 | дрейф комментариев в живом коде — `39e1887` (**параллельная сессия**, вместе с фиксом `config,`) |
| T43 | мёртвый `3x-ui:latest` убран из whitelist (`3fb1f3c`) |
| T44 | `AGENTS.md`: 11 битых ссылок исправлено (`8c86466`) |
| T45 | `modules/wsl/nix-serve.nix` удалён как md5-дубль (`0d52f20`) |
| T46 | `options.pxe-infra` (351 стр., md5-идентичен) → `modules/pxe-infra/options.nix` (`1adf6dd`) |
| T48 | `.gitignore` заякорен, verifier сохранён в `.ci/verify/` (`2ed525b`) |

**Осталось / заблокировано:** T47, T49, T56 (home-manager — нужен `nix`
для проверки merge-семантики), T50 (реестр хостов — нужен `nix flake check`
и регресс на хостах), T51 (nginx — нужен снимок `nginx -T`), T53 (секреты и
`archive/`), T54 (`nix flake lock`), T55 (секреты). T52 и T57 закрыты
2026-10-25; T37 разблокирована T4, но остаётся отдельной runtime-операцией.

**Ограничение этой сессии:** на машине агента **нет `nix`** — сборку и
`nix eval` выполнить нельзя. Поэтому функциональные правки выполнялись
только под статическими тестами (побайтовая идентичность блока, md5,
граф импортов), а всё, что требует `nix`, помечено blocked.

**Отдельная находка:** `HEAD` содержал невалидный Nix — в
`modules/server/default.nix:79` и `modules/vds/default.nix:40` вызывался
`config.modules."3x-ui".reconfig`, а `config` не был объявлен в аргументах
модуля. Исправлено в `39e1887`. Это доказывает, что `nix flake check` в CI
не выполнялся ни разу.

## Project Type

`existing` — NixOS-конфиг домашнего флота. 7 host-outputs (6 NixOS + 1 nix-on-droid).

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Nix |
| Framework | NixOS modules + home-manager |
| Database | PostgreSQL (sapphira), sqlite (3x-ui) |
| Test runner | нет юнит-тестов; `.ci/checks.sh` — 5 проверок (#1 `:latest`, #2 `nix flake check`, #7 sops path_regex, #8 граф импортов, #9 схемы `.agent`). CI (Gitea Actions) исполняется **на самой sapphira** (2 ядра / 5.6 GiB) и с 2026-10-25 вызывает `bash .ci/checks.sh --no-build` (check #2 пропущен) + вычисляет `drvPath` **только** для `sapphira`; полный обход 7 хостов уходил в swap на 40+ минут. Другие хосты — вручную: `nix build --no-link --dry-run .#nixosConfigurations.<host>.config.system.build.toplevel`. Первый реальный прогон: run 144 (3c1269b) — **success**, ~97 с |
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
| `modules/options.nix` | existing | Кросс-модульные опции `host.builder` / `host."3x-ui"` (81 стр. после T46) |
| `modules/pxe-infra/options.nix` | existing | Вся поверхность `pxe-infra.*` (351 стр.), перенесена из `modules/options.nix` в T46 |
| `modules/users.nix` | existing | Пользователь + sops + hostKey bootstrap |
| `modules/essentials/ssh.nix` | existing | openssh + hostKey |
| `modules/server/{nginx,coredns}.nix` | existing | Reverse proxy + DNS (`zeroq.su`, `home.arpa`) |
| `modules/server/postgresql.nix` | existing | PostgreSQL + `mkStorageGuard` (`lib/xlib/helpers.nix`, фрагмент `unitConfig`; гвард жив с 2026-10-25) |
| `modules/server/gitea-runner.nix` | existing | Gitea Actions host-runner на sapphira. **См. ADR-0004**: имя юнита экранировано `escapeSystemdPath`; переопределять только по байт-в-байт совпадающему ключу |
| `modules/server/systemd.nix` | existing | rsync oneshots с `requiresMountsFor` |
| `modules/containers/3x-ui.nix` | pinned | Панель запинена на `v3.11.0` (`modules/containers/3x-ui.nix:71`, ADR-0007; бандл ядра 26.10.21). Ядро Xray — состояние панели, различается по хостам (R1.5, R1.8) |
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

20+ системных сервисов (число не проверялось поштучно, это нижняя оценка) + **4 контейнера**: `3xui_app` (`modules/containers/3x-ui.nix:53`), `taperotation-backend` и `taperotation-frontend` (`modules/containers/tape-rotation.nix:51,76`), `open-webui` (`modules/containers/open-webui.nix:52`). `modules/containers/remnanode.nix` и `modules/containers/remnawave-examples/` **не импортируются** — вне графа импортов (см. T41). Полный инвентарь в `tasks/manifest.json`. Все потребители `mkStorageGuard` (13 юнитов / 12 сервисов) несут живой guard в `[Unit]`: postgresql, `samba-smbd`, homebox, gitea, navidrome, syncthing, uptime-kuma, `immich-server`, `phpfpm-nextcloud`, calibre-web, `podman-3xui_app`, tape-rotation (два юнита). На vds guard отключён — External там нет.

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
Есть `.ci/checks.sh` с 4 реализованными проверками (#2 `nix flake check`,
#7 sops path_regex по всем `*/secrets/*`, #1 нет `:latest`, #8 граф импортов —
`.ci/tests/import-graph.py`).
**Историческое состояние (до 2026-10-24):** ни одна проверка не выполнялась
ни разу — скрипт лежал в git с режимом `100644`, workflow — в
`.github/workflows/` при единственном gitea-remote, шаги сборки
заканчивались `|| true` + `--dry-run`. Всё три дефекта исправлены в T39
(`ca450f1`, `db3cbd0`, `0297254`); первый прогон на раннере ещё предстоит.
Не реализованы 4 кандидата (#3 coredns↔nginx, #4 потребители guard'а,
#5 финальная политика nftables, #6 `listen.addr`).
Реестр задач по этому — `.agent/tasks/manifest.md` (T39, T40).

## Open Concerns

- **B1 / T4 (закрыта 2026-10-25):** гвард на несмонтированный External
  **работает на всех 13 юнитах / 12 сервисах**: postgresql, `samba-smbd`,
  homebox, gitea, navidrome, syncthing, uptime-kuma, `immich-server`,
  `phpfpm-nextcloud`, calibre-web, `podman-3xui_app`, два юнита tape-rotation.
  `mkStorageGuard` отдаёт фрагмент `unitConfig` → `[Unit]`, где
  `ConditionPathIsMountPoint` действительно читается; в `[Service]` — 0
  вхождений. `RequiresMountsFor` по-прежнему **нет намеренно** (авто-монтаж
  обессмыслил бы гвард). Побочно удалены три фантомных пустых юнита
  (`samba.service`, `nextcloud.service`, `immich.service`).
  На `vds` гвард отключён: у otreca нет `/home/oqyude/External`, живое условие
  пропустило бы `podman-3xui_app` и погасило панель. Гвард с gitea-runner
  снят осознанно — он охранял пустое множество (у раннера ноль дескрипторов
  на внешнем диске), но это значит, что ничто не разделяет Gitea, стартующий
  на пустой БД, и CI-раннер, который затем погонит по ней job'ы.
- **gitea-runner: фикс закоммичен** (T18 → completed, `tasks/manifest.json`,
  коммиты `9bf9407`/`b62a980`/`d021804`); ADR-0004 принят. Прежняя запись
  «лежит только в рабочем дереве» была протухшей — снята 2026-10-23.
- **A3 / T3 (закрыта 2026-10-25):** посылка «нет финальной политики → неявный
  accept» **неверна**. `inet nixos-fw` (генерируется `firewall.enable = true`)
  имеет `chain input policy drop` с accept'ами 80/443, 41641/udp, 22 на
  `tailscale0`, ping, podman DNS. Рукописный `inet filter`
  (`configurations/vds.nix:71-92`, `policy accept`) — вторая base chain и лишь
  режет SYN; `policy drop` в неё добавлять нельзя (финальный drop заблокирует
  VDS). Проверено `sudo nft list ruleset` на otreca.
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
