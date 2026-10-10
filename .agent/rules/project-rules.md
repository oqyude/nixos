# Project Rules

Правила, которым агент обязан следовать во всех фазах. Источник: старый
`AGENTS.md` (накоплен при проходе по репозиторию 2026-10-05, ответы владельца
учтены 2026-10-05). Дополнения и уточнения — через `/adr`.

## Обязательные правила

### R1. Не ломать подтверждённые инварианты

1. **Все `outputs` флейка должны вычисляться.** `configurations/mobile.nix:12`
   импортировал несуществующий `lib/xlib.nix` — был сломан, `epral` не
   собирался. Закреплено через `nix flake check`.
2. **Носитель данных (`/home/oqyude/External`) обязан быть смонтирован** до
   старта `postgresql`, `samba`, `homebox`, `gitea`, `navidrome`, `syncthing`,
   `uptime-kuma`, `immich`, `nextcloud`, `calibre-web`, `3x-ui`, `tape-rotation`.
   `mkStorageGuard` (T4) добавляет `RequiresMountsFor` + `ConditionPathIsMountPoint`
   на `server-home` — без guard'а сервис стартует на пустой БД. → задача T4.
3. **Сетевая граница sapphira — роутер.** `firewall.enable = false` намеренно.
   Роутер пробрасывает ровно 5 портов: **443, 80, 22000 (syncthing),
   8443 (xray), 22 (ssh)**. `nginx.nix` (networking.firewall) `allowedTCPPorts`
   мёртв (T13). `openFirewall`/`allowedTCPPorts` на sapphira не имеют эффекта.
4. **`100.64.0.0` = Tailscale-адрес sapphira**, назначен вручную. Не сеть, не
   ошибка. Используется в `home/termux.nix:256`, `modules/server/nextcloud.nix:73`
   (`trusted_proxies`), `modules/server/nginx.nix:109,253`,
   `modules/vds/systemd.nix:10`. При смене — править 4 файла.
5. **3x-ui заморожен.** Панель на последней версии (образ `:latest`),
   ядро Xray на 26.7.x. Миграция на 26.9.x провалена. Обходные скрипты
   (timer, migrateScript) отключены осознанно. **Не** обновлять ядро через
   панель без записи в `decisions/` или `notes/`.
6. **nftables на VDS требует явной финальной политики.** Текущий ruleset
   (`vds.nix:73-91`) — без явного последнего правила и без `policy` → неявный
   accept. На otreca одновременно `nftables.enable = true` и `firewall.*` —
   проверить, кто реально владеет ruleset'ом, перед правкой.
7. **sops-пути — через `config.sops.secrets.<name>.path`.** Любой
   `path =` override на sops-блоке делает хардкод-потребителя молча
   сломанным: rebuild зелёный, сервис стартует, контент пустой. См. ADR-0001.
8. **Версия ядра Xray — состояние UI-панели 3x-ui, не Nix.** Ядро
   ставится через UI панели (UI → xray version) и хранится в её
   sqlite-БД. Перед любым деплоем/ребутом 3x-ui — проверить версию
   ядра в панели. Nix декларирует панель (`:latest`), но не ядро.
9. **Backups: external/unknown — accepted risk.** На 2026-10-10 open question
   5.6 («где бэкапы, как проверяются?») не отвечен владельцем. В этом
   репозитории **не декларируется** ни одна бэкап-стратегия. Failure modes
   (потеря `/dev/sdc1` = потеря всех 9 сервисов на sapphira) перечислены
   в `.agent/decisions/0002-backups-external.md`. Если в будущем
   бэкап-система появится — отменить этот R1.9 и зафиксировать R1.x
   про регулярную верификацию.
10. **`reality443Forwarding = true` на VDS обязателен, НЕ удалять.**
    `modules/vds/nginx.nix` маршрутизирует реальный `443` через stream:
    `pubray1.zeroq.su → 127.0.0.1:2049` (панель), всё остальное
    (в т.ч. SNI `media.mediavitrina.ru` для REALITY-клиентов) →
    `127.0.0.1:15380 → container:443`. Маппинг `127.0.0.1:15380:443/tcp`
    публикует опция `reality443Forwarding` (T10/C5 «погасил» её 2026-10-10 —
    Xray REALITY стал недоступен при живых SSH и pubray1.zeroq.su;
    восстановлено `07a0437`, manifest T10 → status `pending`).
    **Сигнатура отказа НЕ выглядит как «Xray упал»** (2026-10-10, T10):
    контейнер здоров, `restarts=0`, ядро 26.7.28 на месте, SSH жив, панель по
    SNI `pubray1.zeroq.su` отвечает валидным сертификатом — но в журнале nginx
    `connect() to 127.0.0.1:15380 failed (111: Connection refused)` и масса
    `worker_connections are not enough`. Диагностировать «панель/Xray» надо
    **пробой порта 15380 и `podman inspect .NetworkSettings.Ports`**, а не по симптому.
11. **Декларация портов ≠ runtime.** `ports` в
    `virtualisation.oci-containers.containers."3xui_app"`
    (`modules/containers/3x-ui.nix:26-35,68`) применяются **только при
    пересоздании контейнера**. Правка Nix без `nixos-rebuild switch` не меняет
    ничего; проверка после деплоя — обязательна:
    ```bash
    sudo podman inspect 3xui_app --format '{{json .NetworkSettings.Ports}}'  # ждём 15380
    ```
    Любой ребилд, пересоздающий `3xui_app`, = окно недоступности REALITY
    (2026-10-10: `07a0437` 17:54:18 → контейнер пересоздан 17:55:38).
    Клиенты в это окно уходят в ретрай-флуд (см. R1.12 и ADR-0003).
12. **`x-ui.db` не откатывать на `x-ui.db.bak.1787862834`.** Живая БД —
    `/mnt/services/nodes/otreca/3x-ui/db/x-ui.db` (в контейнере
    `/etc/x-ui/x-ui.db`), схема **v3**, колонка `stream_settings`.
    Бэкап от 2026-08-27 (311296 B) — **другая конфигурационная эпоха**:
    инбаунды `id` 3/39/15/33 на портах **14380/14480/14910/14920**
    (tcp/xhttp/xhttp/grpc), 7 клиентов, без `dest media.mediavitrina.ru`.
    Текущая БД: `id` 42/45/46 на **443/8443/18443** (xhttp+reality), 11 клиентов.
    Откат заменит рабочие инбаунды и обесценит все 11 клиентских конфигов.
13. **TLS терминирует панель 3x-ui, не nginx.** На otreca nginx в `stream`
    делает только `ssl_preread` и проксирует сырой TCP; TLS живёт **внутри**
    контейнера. Сертификат: хост `/var/lib/acme/pubray1.zeroq.su/{fullchain,key}.pem`
    → bind-mount `ro` в `/root/cert/*`; в настройках панели
    `webCertFile=/root/cert/fullchain.pem`, `webKeyFile=/root/cert/key.pem`.
    **Не добавлять** TLS-терминирующий `server {}` для `pubray1.zeroq.su` —
    перекроет stream-SNI карту и убьёт и панель, и REALITY.

### R2. home-manager `Service` ≠ `serviceConfig`

`home/modules/opencode.nix:339-350` (`c73a698`): в home-manager нельзя писать
`serviceConfig = { ... }` — рендерится литеральная секция `[serviceConfig]`,
которую systemd молча игнорирует («Unknown section 'serviceConfig'. Ignoring.»).
Правильно: `systemd.user.services.opencode-web.Service = { ... }`. В home-manager
cgroup-опции (`MemoryHigh`, `OOMScoreAdjust`, …) пишутся в
`systemd.user.services.<name>.Service`, **не** в `serviceConfig`. Ошибка
не диагностируется — она просто не применяется.

### R3. Sops-цикл ключа задокументировать

`/etc/ssh/id_ed25519` одновременно: `hostKeys` для sshd, `sops.age.sshKeyPaths`
для расшифровки, цель `ssh_key_private_known`, цель `ssh_key_public_host`.
Как разворачивается на чистой машине — **одноразовый bootstrap**. Должен быть
задокументирован, иначе при переустановке хоста агент не выведет.

### R4. Перед деплоем External-диска — `findmnt`

Перед рестартом сервисов, использующих `mkServiceStorage` (postgresql, samba,
homebox, gitea, navidrome, syncthing, uptime-kuma, immich, nextcloud,
calibre-web, 3x-ui, tape-rotation):

```bash
findmnt /home/oqyude/External
findmnt /mnt/services
```

До реализации guard'а (задача B1) — это единственная защита от старта на
пустой БД.

### R5. Проверка целостности sops-секретов

Любая правка `users.nix` или потребителя sops-секрета требует:

```bash
sops --version
nix build .#nixosConfigurations.<хост>.config.system.build.toplevel --dry-run
```

Расшифровка sops-секретов зависит от `/etc/ssh/id_ed25519` (см. R3).
Циклическая зависимость — см. «Где НЕ лезть без ответа».

## Ловушки (выглядит сломанным, намеренно)

Прежде чем чинить — проверить этот список. Здесь лежат решения, которые
иначе «поправляются» обратно и ломают рабочую систему.

| Где | Что выглядит ошибкой | На самом деле |
|---|---|---|
| `server.nix:130` | `firewall.enable = false` при 20 сервисах на `0.0.0.0` | Роутер фильтрует, см. R1.3 |
| `mobile.nix:95`, `wsl.nix:59` | `stateVersion` 24.05 / 24.11 vs 26.05 | Каждый хост зафиксирован на своей версии |
| `users.nix:66` | `uid = if hostname == "sapphira" then 1001 else …` | Костыль под 1000 = удалённый `yuyus`; удалять только после миграции ФС |
| `3x-ui.nix:54` | `image = …:latest` | Панель намеренно latest; ядро Xray — состояние панели, см. R1.8 |
| `3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS | **Обязательно, НЕ удалять** (R1.10). nginx stream (`vds/nginx.nix`) маршрутизирует `443 → 127.0.0.1:15380 → container:443`; без маппинга Xray REALITY мёртв. Удаление T10/C5 сломало — восстановлено `07a0437` |
| `vds/nginx.nix`, `events {}` | Пустой блок → `worker_connections` = **512** (дефолт) | Не баг, но и не запас: при окне недоступности REALITY клиенты дают ретрай-флуд и исчерпывают 512 → «не работает всё» даже после починки первопричины (2026-10-10: 1668 ошибок за ~40 мин). Известный пробел, задача не заведена |
| Настройки панели, `webBasePath = /pubray/` | `GET https://pubray1.zeroq.su/` → **404, 0 байт** | Панель жива, корень не корень. Реальный URL — `https://pubray1.zeroq.su/pubray/` (HTTP 200). `/subs/` без токена тоже 404 — это норма. Не «чинить» nginx под `/` |
| `server/default.nix:37-50` | 14 закомментированных модулей (13 архивировано, 1 stirling-pdf удалён в 5dd7a58) | Отключены осознанно, см. задачу T16 |
| `opencode.nix:339` | `systemd.user.services.opencode-web.Service` | `serviceConfig` рендерится в секцию `[serviceConfig]`, systemd молча игнорирует (`c73a698`); см. R2 |
| `vds.nix:73-91` | nftables без финального правила | Известный пробел, см. задачу A3 |
| `100.64.0.0` | Первый адрес CGNAT `/10` | Tailscale-адрес sapphira, см. R1.4 |
| `server.nix:61-63` | `z /mnt/services 0777` | World-writable точка монтирования; см. задачу B1 |

## Куда лезть по задаче

| Задача | Файл |
|---|---|
| Добавить хост | `configurations/default.nix` + `configurations/<host>.nix` + `configurations/{hardware,disko}/<host>.nix` |
| Добавить системный сервис | `modules/server/<name>.nix`, добавить в `modules/server/default.nix:imports` |
| Добавить home-пакет для пользователя | `home/<device_type>.nix` (через `lib.mkIf` или просто список) |
| Добавить опцию, читаемую несколькими модулями | `modules/options.nix` |
| Изменить mount/имя пользователя | `lib/xlib/dirs.nix`, `lib/xlib/device.nix` |
| Изменить домен / сертификат | `modules/server/coredns.nix` + `modules/server/nginx.nix` (или `vds/`) |
| Sops-секрет | положить в `secrets/<name>.<yaml\|json\|env\|ini>`; `users.nix:99` уже подключает `secrets/default.yaml`; dotenv/json-секреты — через `mkUserSecret` |

## Где НЕ лезть без ответа владельца

- `secrets/` (sops-encrypted, расшифровываются `/etc/ssh/id_ed25519` → циклический bootstrap).
- `let deploy` без проверки deploy-rs нод: `rydiwo` (ноутбук, может быть выключен).
- Любая правка, противоречащая «Подтверждённым инвариантам» выше (R1).
- `vetymae` / `lamet` / `therima` / `soptur` в `dirs.nix` — природа неясна (открытый вопрос 2.2/5.5).
- `192.168.1.20` в 30 местах — менять только при готовности править все места (открытый вопрос 6.6).
- Ядро Xray 26.7.x → 26.9.x — миграция провалена, не повторять без отдельной задачи.

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

# state of guard-зависимостей (когда будет todo B1)
systemctl show postgresql -p Requires -p After | tr ' ' '\n' | grep -E 'mnt-|home-oqyude'

# sops
sops --version

# цепочка 3x-ui REALITY на otreca (после любого деплоя, трогающего 3x-ui/nginx)
sudo podman inspect 3xui_app --format '{{json .NetworkSettings.Ports}}'          # есть 15380->443
sudo podman exec 3xui_app /app/bin/xray-linux-amd64 version          # ожидаем 26.7.x
curl -ks --resolve pubray1.zeroq.su:443:127.0.0.1 -o /dev/null \
  -w '%{http_code}\n' https://pubray1.zeroq.su/pubray/            # ожидаем 200
sudo journalctl -u nginx --since '-10 min' | grep -cE 'worker_connections|Connection refused'  # ожидаем 0
```

## Диагностика «REALITY на otreca не работает» (порядок, 2026-10-10)

1. `sudo podman inspect 3xui_app --format '{{json .NetworkSettings.Ports}}'` — есть ли `15380->443`.
   Нет → R1.10/R1.11 (декларация разошлась с runtime), контейнер не пересоздан.
2. `sudo podman exec 3xui_app /app/bin/xray-linux-amd64 version` — должно быть
   26.7.x (R1.8). Не 26.9.x. **В `$PATH` контейнера бинаря нет** — только
   полный путь.
3. `sudo podman exec 3xui_app python3 -c "import sqlite3;…"` — `inbounds` в
   `x-ui.db` (колонка `stream_settings`): порты 443/8443, `network=xhttp`,
   `security=reality`, `enable=1`. Сверить с `/app/bin/config.json` внутри контейнера.
4. Проба 443 снаружи: TLS с SNI `media.mediavitrina.ru` должен вернуть
   steal-сертификат `*.mediavitrina.ru`; SNI `pubray1.zeroq.su` — валидный
   сертификат панели.
5. Только если 1–4 зелёные, а пользователь всё ещё видит отказ — проблема
   клиентская (старый конфиг, клиент без поддержки `xhttp`).

## Конвенции проекта

- `xlib` (в `lib/xlib/`) — чистые данные: identity (`device`), capability flags,
  директории, helper'ы. Передаётся в каждый модуль через `specialArgs`.
  Конфиг не может переопределить `xlib` — единственная точка изменения это
  `configurations/default.nix`.
- `device.type` ∈ { minimal, primary, secondary, server, vds, wsl, termux }.
  `modules/defaultModule` импортирует `modules/<type>/` через
  `lib.optional (!isDesktop && type != "minimal") (./. + "/${type}")`.
- `mkXlib` (`lib/xlib/default.nix:38-77`) — единственная точка сборки xlib.
- Опция живёт в `modules/options.nix`, если её **устанавливает** один модуль,
  а **читает** другой. `host.reader.X.enable` живёт в `essentials/ssh.nix`,
  потому что его объявляет и использует один модуль.
- `home/<type>.nix` = единственный источник «что есть на этом хосте» для
  пользователя; добавление пакета в новый тип = правильный файл, а не
  `home/default.nix`.
- `.sops.yaml`: один age-ключ (`*default`), `path_regex: secrets/[^/]+\.(yaml|json|env|ini)$`.
  Покрывает только плоские файлы в `secrets/` (без подкаталогов). Дополнительные
  секреты dotenv/json — через `mkUserSecret` (`users.nix:33-41`).
