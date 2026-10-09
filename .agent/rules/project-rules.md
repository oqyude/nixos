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
   старта `postgresql`, `n8n`, `samba`, `homebox`, `minecraft`, `3x-ui`,
   `tape-rotation`. `mkServiceStorage` даёт `bind,x-systemd.automount,nofail`
   — без guard'а сервис стартует на пустой БД. Задача `B1` в `manifest.json`.
3. **Сетевая граница sapphira — роутер.** `firewall.enable = false` намеренно.
   Роутер пробрасывает ровно 5 портов: **443, 80, 22000 (syncthing),
   8443 (xray), 22 (ssh)**. `nginx.nix:225` (`allowedTCPPorts = [80 443]`) мёртв.
   `openFirewall`/`allowedTCPPorts` на sapphira не имеют эффекта.
4. **`100.64.0.0` = Tailscale-адрес sapphira**, назначен вручную. Не сеть, не
   ошибка. Используется в `nginx.nix`, `nextcloud.nix` (`trusted_proxies`),
   `vds/systemd.nix`, `vds/nginx.nix`. При смене — править 4 файла.
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
| `3x-ui.nix:54` | `image = …:latest` | Панель намеренно latest; ядро Xray — на 26.7.x |
| `3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS | Следствие отката `c8d4a12`; смысл утрачен, см. задачу C5 |
| `server/default.nix:33-47` | 15 закомментированных модулей | Отключены осознанно, см. задачу E3 |
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
```

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
