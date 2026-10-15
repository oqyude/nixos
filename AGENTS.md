---
aliases: []
cssclasses: 
date-created: 2026-10-09T19:01
date-modified: 2026-10-15T17:42
tags: [metaagent, nixos, agents]
---
# AGENTS.md

Этот проект использует [MetaAgent](.agent/src/GUIDE.md) v3.0.0 — набор
инструкций для AI-агента.

> NixOS-конфиг домашнего флота. 6 NixOS-хостов + Android (`nix-on-droid`).
> Этот файл — то, что агент должен прочитать **до** первого изменения. Если
> задача выглядит так, что требует сломать что-то из «Подтверждённых
> инвариантов» или «Ловушек» ниже — остановиться и спросить.

## Контекст MetaAgent

| Ресурс | Путь |
|--------|------|
| Главная инструкция | `.agent/src/GUIDE.md` |
| Протоколы фаз | `.agent/src/PROTOCOLS/` |
| Команды (on-demand) | `.agent/src/COMMANDS/` |
| Шаблоны артефактов | `.agent/src/TEMPLATES/` |
| Границы (что разрешено/запрещено) | `.agent/src/BOUNDARIES.md` |
| История версий | `.agent/src/CHANGELOG.md` |
| Правила проекта (полные) | `.agent/rules/project-rules.md` |
| Слепок проекта | `.agent/context/project-state.md` |
| Анализ репозитория | `.agent/context/analysis-report.md` |
| Дорожная карта | `.agent/roadmap/sources.md` |
| Манифест задач | `.agent/tasks/manifest.json` |
| ADR (архитектурные решения) | `.agent/decisions/` |
| Пример работы | `.agent/src/WORKFLOW.md` |
| Версия | `.agent/src/VERSION` |

## Архитектура (30 секунд)

```
flake.nix
├── configurations/         ← реестр хостов (1 запись = 1 машина)
├── modules/                ← essentials + per-type (desktop/server/vds/wsl/containers/termux)
├── home/                   ← home-manager (per device-type)
├── lib/xlib/               ← чистые данные: devices, dirs, helpers
├── deploy/, secrets/ (sops), overlays/, pkgs/
└── .agent/                 ← MetaAgent state (rules, decisions, tasks, context, requests, roadmap)
```

Подробная карта: `.agent/context/project-state.md` и `.agent/context/analysis-report.md`.

## Хосты

| Attr / имя | device.type | Роль | Деплой | stateVersion | Примечание |
|---|---|---|---|---|---|
| `default` (nixos) | minimal | Шаблон / минималка | — | — | hostname `"nixos"` |
| `atoridu` | primary | Основной десктоп | — (manual) | 26.05 | xanmod, mini-PC |
| `rydiwo` | secondary | Chuwi MiniBook | deploy-rs | 26.05 | xanmod, NTFS `lamet-drive` |
| `otrecа` | vds | VPS | deploy-rs | 25.05 | Tailscale-only SSH, nftables (см. T3) |
| `sapphira` | server | Домашний сервер | deploy-rs | 25.05 | `firewall.enable = false` намеренно |
| `wsl` | wsl | WSL NixOS | — (manual) | 24.11 | на vetymae (Windows 192.168.1.100) |
| `epral` | termux | Android | — | 24.05 | nix-on-droid, через `mobile.nix` |

## Подтверждённые инварианты

> Полные формулировки (с «Где» и «Почему») — в `.agent/rules/project-rules.md` (R1).

1. **Все `outputs` флейка должны вычисляться.** `configurations/mobile.nix:12` импортировал несуществующий `lib/xlib.nix` — был сломан, `epral` не собирался. → задача T1.
2. **External-диск обязан быть смонтирован** до старта `postgresql`, `samba`, `homebox`,
   `gitea`, `navidrome`, `syncthing`, `uptime-kuma`, `immich`, `nextcloud`,
   `calibre-web`, `3x-ui`, `tape-rotation` — **но гвард мёртв.** `mkStorageGuard`
   отдаёт только `ConditionPathIsMountPoint` (директива `[Unit]`), а все 12 потребителей
   передают её через `serviceConfig` → рендерится в `[Service]`, где systemd её не читает.
   `RequiresMountsFor` нет **намеренно**: авто-монтирование systemd обессмыслило бы гвард.
   Мёртв на **13 юнитах / 12 сервисах**. «`serviceConfig` не мержится» — ложный вывод:
   мержится, проблема в секции. → задача T4, ADR-0004.
3. **Сетевая граница sapphira — роутер.** 5 портов: **443, 80, 22000 (syncthing), 8443 (xray), 22 (ssh)**. `firewall.enable = false` намеренно. nginx.nix (networking.firewall) мёртв (T13). → задача T11.
4. **`100.64.0.0` = Tailscale-адрес sapphira**, назначен вручную. В `home/termux.nix:256`,
   `modules/server/nextcloud.nix:80`, `modules/server/nginx.nix:109,253`,
   `modules/vds/systemd.nix:10`. → задача T12.
5. **3x-ui заморожен.** Панель на `:latest`, ядро Xray на 26.7.x. Миграция на 26.9.x провалена. → задачи T6–T10.
6. **nftables на VDS требует явной финальной политики.** Текущий ruleset — без финального правила → неявный accept. → задача T3.
7. **sops-пути — через `config.sops.secrets.<name>.path`.** Любой `path =` override на sops-блоке делает хардкод-потребителя молча сломанным. → ADR-0001.
8. **Декларация портов ≠ runtime.** `ports` контейнера `3xui_app` применяются только при пересоздании; правка Nix без `nixos-rebuild` не меняет ничего. Проверка: `podman inspect 3xui_app --format '{{json .NetworkSettings.Ports}}'`. → R1.11, ADR-0003.
9. **`x-ui.db` не откатывать на `x-ui.db.bak.1787862834`.** Бэкап от 2026-08-27 — другая эпоха (порты 14380/14480/14910/14920, 7 клиентов). Откат убьёт рабочие 443/8443 и все 11 конфигов. → R1.12, ADR-0003.
10. **TLS терминирует панель 3x-ui, не nginx.** nginx делает только `ssl_preread` и проксирует сырой TCP; сертификат смонтирован в контейнер `ro`. TLS-терминирующий `server {}` для `pubray1.zeroq.su` перекроет stream-SNI и убьёт и панель, и REALITY. → R1.13, ADR-0003.
11. **Имя `systemd.services.<…>` должно побайтово совпадать с тем, что upstream отдал `nameValuePair`.** `escapeSystemdPath` превращает `-` в литеральную строку `\x2d`, поэтому настоящий ключ — `gitea-runner-ci\x2dsapphira` (обратный слэш, не дефис). Обе формы рендерятся в **один** файл `gitea-runner-ci-sapphira.service`, но это **два разных атрибута**: неэкранированная запись создаёт фантом без `ExecStart`, фантом выигрывает рендер, и systemd отказывается стартовать (`Service has no ExecStart=… Refusing.`). Юнит молчал 12 часов, система при этом собиралась без ошибок. Проверять только чтением файла юнита: `systemctl show gitea-runner-ci-sapphira` отдаёт **дефолты**, а не реальные значения. → R1.14, ADR-0004.
12. **`herdr.zeroq.su` — за nginx без authelia, только herdr token.** Vhost в `modules/server/nginx.nix` (правки в 4d1426c, 61ad57a, 9bf9407) обходит `authelia` subrequest. Причины: (а) `error_page 401 =302` редирект работает для GET, но POST через authelia → 500; (б) `sameOrigin()` в upstream `server/machine-security.ts:18-46` не читает `X-Forwarded-Host` → 403 `invalid_origin` на каждом cross-origin POST за reverse proxy. Auth model: `herdr_web_token` (256 бит, HttpOnly Secure SameSite=Strict, 1 год), brute-force защищён rate-limit в `server/auth.ts:18-28,53-71` (5/адрес, doubling backoff до 60s, 1024 LRU). **Maintenance:** in-place patch в `server/machine-security.ts` на sapphira (`*.orig` рядом) держится до T29 (PR в upstream с поддержкой `X-Forwarded-Host`); `herdr plugin update devswha/herdr-web-ui` перезаписывает файл. Подробности в ADR-0005 → R1.15.

## Ловушки (выглядит сломанным, намеренно)

| Где | Что выглядит ошибкой | На самом деле |
|---|---|---|
| `server.nix:130` | `firewall.enable = false` при 20 сервисах на `0.0.0.0` | Роутер фильтрует, см. инв. 3 |
| `mobile.nix:95`, `wsl.nix:59` | `stateVersion` 24.05 / 24.11 vs 26.05 | Каждый хост зафиксирован на своей версии |
| `users.nix:66` | `uid = if hostname == "sapphira" then 1001 else …` | Костыль под 1000 = удалённый `yuyus`; удалять только после миграции ФС |
| `3x-ui.nix:54` | `image = …:latest` | Панель намеренно latest; ядро Xray — на 26.7.x |
| `3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS | **Обязательно, НЕ удалять.** nginx stream (`vds/nginx.nix`) маршрутизирует `443 → 127.0.0.1:15380 → container:443`; без маппинга Xray REALITY мёртв. Удаление T10/C5 сломало — восстановлено `07a0437` |
| `vds/nginx.nix`, `events {}` | Пустой блок → `worker_connections` = **512** (дефолт) | Не баг, но и не запас: при окне недоступности REALITY клиенты дают ретрай-флуд и исчерпывают 512 → «не работает всё» даже после починки первопричины (1668 ошибок за ~40 мин). Известный пробел |
| Настройки панели | `GET https://pubray1.zeroq.su/` → **404** | Панель жива: `webBasePath=/pubray/`, реальный URL `https://pubray1.zeroq.su/pubray/`. Не «чинить» nginx под `/` |
| `modules/server/default.nix:7-44` | Комментарий-блок на строках 38-41 выглядит как «список отключённых модулей» | T16 завершена: закомментированных импортов 0. `archive/server-modules/` — 12 файлов (coturn, mealie, memos, minecraft, n8n, netdata, nfs, rsync, step-ca, transmission, trilium, zerotier); `archive/containers/` — `remnawave.nix`, `kokoro-tts.nix`, `openhands.nix`; `stirling-pdf.nix` удалён в `5dd7a58` (поглощён `bentopdf.nix`); `open-webui.nix` переехал в `modules/containers/` и активен |
| `home/modules/opencode.nix:407` | `systemd.user.services.opencode-web.Service` | Правильный паттерн, не баг. Баг `serviceConfig` был и исправлен в `c73a698`, ссылка на строку 339 устарела. R2 удерживает от возврата |
| `vds.nix:73-91` | nftables без финального правила | Известный пробел, см. задачу T3 |
| `100.64.0.0` | Первый адрес CGNAT `/10` | Tailscale-адрес sapphira, см. инв. 4 |
| `server.nix:61-63` | `z /mnt/services 0777` | World-writable точка монтирования; см. задачу T4 |

## Куда лезть по задаче

| Задача | Файл |
|---|---|
| Добавить хост | `configurations/default.nix` + `configurations/<host>.nix` + `configurations/{hardware,disko}/<host>.nix` |
| Добавить системный сервис | `modules/server/<name>.nix`, добавить в `modules/server/default.nix:imports` |
| Добавить home-пакет | `home/<device_type>.nix` |
| Добавить кросс-модульную опцию | `modules/options.nix` |
| Изменить mount/имя пользователя | `lib/xlib/dirs.nix`, `lib/xlib/device.nix` |
| Изменить домен / сертификат | `modules/server/coredns.nix` + `modules/server/nginx.nix` (или `vds/`) |
| Sops-секрет | `secrets/<name>.<yaml\|json\|env\|ini>`; `users.nix:99` подключает `secrets/default.yaml`; dotenv/json — через `mkUserSecret` |

## Проверки

```bash
# все outputs вычисляются
nix flake check

# правки применились на целевой хост
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# nixOnDroid
nix build .#nixOnDroidConfigurations.epral.config.system.build.toplevel

# внешний диск смонтирован (до рестарта сервисов на нём)
findmnt /home/oqyude/External
findmnt /mnt/services

# sops
sops --version
```

## Где НЕ лезть без ответа владельца

- `secrets/` (sops-encrypted, расшифровываются `/etc/ssh/id_ed25519` → циклический bootstrap).
- `let deploy` без проверки deploy-rs нод: `rydiwo` (ноутбук, может быть выключен).
- Любая правка, противоречащая «Подтверждённым инвариантам» выше.
- Ядро Xray 26.7.x → 26.9.x — миграция провалена, не повторять без отдельной задачи.

## Команды MetaAgent (on-demand)

- `/adr` — записать архитектурное решение
- `/red-team` — попытаться сломать дизайн
- `/risk-register` — зафиксировать допущения
- `/alt-arch` — описать альтернативу
- `/invariant-tests` — тесты-инварианты для ADR

## Жизненный цикл MetaAgent v3.0.0

```
INIT → ANALYSE → ROADMAP → [DESIGN] → DECOMPOSITION → EXECUTION → METASTATE → HANDOFF
```

Текущее состояние: см. `.agent/checkpoints.json` (`phases.init = completed`,
`phases.analyse = completed`, `phases.roadmap = completed`,
`phases.decomposition = completed`, `phases.execution = in_progress`,
`phases.metastate = completed`, `phases.handoff = pending`). `execution` остаётся
`in_progress`, пока открыты high-severity задачи (T4 — мёртвый mount-guard, T20 —
`.ci/checks.sh` без execute-бита). Список задач — только в
`.agent/tasks/manifest.json`; `checkpoints.json` — состояние сессии, не задач.
