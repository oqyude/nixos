# AGENTS.md

NixOS-конфиг домашнего флота. 6 NixOS-хостов + Android (`nix-on-droid`).

Этот файл — то, что агент должен прочитать **до** первого изменения. Если задача
выглядит так, что требует сломать что-то из «Подтверждённых инвариантов» или
«Ловушек» ниже — остановиться и спросить.

## Архитектура (30 секунд)

```
flake.nix
├── configurations/         ← реестр хостов (1 запись = 1 машина)
│   ├── default.nix         ← hosts + xlibLib + mkSystem
│   ├── <host>.nix          ← модульное тело хоста
│   └── hardware/<host>.nix
├── home/                   ← home-manager (per device-type)
├── modules/
│   ├── options.nix         ← кросс-модульные опции
│   ├── default.nix         ← defaultModule + strictModule (для nix-on-droid)
│   ├── essentials/         ← packages, services, settings, ssh, shell, systemd-routines
│   ├── desktop/, server/, server/├── vds/, wsl/, containers/, termux/, other/
├── lib/
│   ├── mkSystem.nix        ← nixosSystem + specialArgs(xlib, inputs)
│   └── xlib/               ← чистые данные: devices, dirs, helpers
├── overlays/, pkgs/, deploy/, secrets/ (sops)
└── .sops.yaml                ← один age-ключ на secrets/<name>.(yaml|json|env|ini)
```

`xlib` (в `lib/xlib/`) — чистые данные: identity (`device`), capability flags,
директории, helper'ы. Передаётся в каждый модуль через `specialArgs`. Конфиг не
может переопределить `xlib` — единственная точка изменения это `configurations/default.nix`.

## Хосты

| Attr / имя | device.type | Роль | Деплой | Примечание |
|---|---|---|---|---|
| `default` (nixos) | minimal | Шаблон / минималка | — | hostname `"nixos"` |
| `atoridu` | primary | Основной десктоп | — | xanmod |
| `rydiwo` | secondary | Ноутбук Chuwi MiniBook (xanmod, NTFS) | deploy-rs | `stateVersion 26.05` |
| `otrecа` | vds | VPS, SSH только по Tailscale | deploy-rs | nftables, DHCP, no firewall в NixOS |
| `sapphira` | server | Домашний сервер (белый IP через роутер) | deploy-rs | `firewall.enable = false` намеренно |
| `wsl` | wsl | WSL NixOS на vetymae | — | nixos-wsl module |
| `epral` | termux | Android (`nix-on-droid`) | — | через `mobile.nix`, отдельный модульный путь |

`device.type` ∈ { minimal, primary, secondary, server, vds, wsl, termux }.
`modules/defaultModule` импортирует `modules/<type>/` через `lib.optional
(!isDesktop && type != "minimal") (./. + "/${type}")`.

## Подтверждённые инварианты

1. **Все `outputs` флейка должны вычисляться.** `configurations/mobile.nix:12`
   импортировал несуществующий `lib/xlib.nix` — был сломан, `epral` не
   собирался. Зафиксировать через `nix flake check`.
2. **Носитель данных (`/home/oqyude/External`) обязан быть смонтирован** до
   старта `postgresql`, `n8n`, `samba`, `homebox`, `minecraft`, `3x-ui`,
   `tape-rotation`. `mkServiceStorage` даёт `bind,x-systemd.automount,nofail`
   — без guard'а сервис стартует на пустой БД. → todo B1.
3. **Сетевая граница sapphira — роутер.** `firewall.enable = false` намеренно.
   Роутер пробрасывает ровно 5 портов: **443, 80, 22000 (syncthing), 8443
   (xray), 22 (ssh)**. `nginx.nix:225` (`allowedTCPPorts = [80 443]`) мёртв.
   `openFirewall`/`allowedTCPPorts` на sapphira не имеют эффекта.
5. **`100.64.0.0` = Tailscale-адрес sapphira**, назначен вручную. Не сеть, не
   ошибка. Используется в `nginx.nix`, `nextcloud.nix` (`trusted_proxies`),
   `vds/systemd.nix`, `vds/nginx.nix`. При смене — править 4 файла.
4. **3x-ui заморожен.** Панель на последней версии (образ `:latest` → запинить),
   ядро Xray на 26.7.x. Миграция на 26.9.x провалена. Обходные скрипты (тimer,
   migrateScript) отключены осознанно. **Не** обновлять ядро через панель без
   записи в `docs/arch/notes/3x-ui-xray-26.9.md`.
6. **nftables на VDS требует явной финальной политики.** Текущий ruleset
   (`vds.nix:73-91`) — без явного последнего правила и без `policy` → неявный
   accept. На otreca одновременно `nftables.enable = true` и `firewall.*` —
   проверить, кто реально владеет ruleset'ом, перед правкой.

## Ловушки (выглядит сломанным, намеренно)

| Где | Что выглядит ошибкой | На самом деле |
|---|---|---|
| `server.nix:130` | `firewall.enable = false` при 20 сервисах на `0.0.0.0` | Роутер фильтрует, см. §4 |
| `mobile.nix:95`, `wsl.nix:59` | `stateVersion` 24.05 / 24.11 vs 26.05 | Каждый хост зафиксирован на своей версии |
| `users.nix:66` | `uid = if hostname == "sapphira" then 1001 else …` | Костыль под 1000 = удалённый `yuyus`; удалять только после миграции ФС |
| `3x-ui.nix:54` | `image = …:latest` | Панель намеренно latest; ядро Xray — на 26.7.x |
| `3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS | Следствие отката `c8d4a12`; смысл утрачен, см. todo C5 |
| `server/default.nix:33-47` | 15 закомментированных модулей | Отключены осознанно, см. todo E3 |
| `opencode.nix:339` | `systemd.user.services.opencode-web.Service` | `serviceConfig` рендерится в секцию `[serviceConfig]`, systemd молча игнорирует (`c73a698`) |
| `vds.nix:73-91` | nftables без финального правила | Известный пробел, см. todo A3 |
| `100.64.0.0` | Первый адрес CGNAT `/10` | Tassigned вручную, см. §5 |
| `server.nix:61-63` | `z /mnt/services 0777` | World-writable точка монтирования; см. todo B1 |

## Куда лезть по задаче

| Задача | Файл |
|---|---|
| Добавить хост | `configurations/default.nix` + `configurations/<host>.nix` + `configurations/{hardware,disko}/<host>.nix` |
| Добавить системный сервис | `modules/server/<name>.nix`, добавить в `modules/server/default.nix:imports` |
| Добавить home-пакет для пользователя | `home/<device_type>.nix` (через `lib.mkIf` или просто список) |
| Добавить опцию, читаемую несколькими модулями | `modules/options.nix` |
| Изменить mount/имя пользователя | `lib/xlib/dirs.nix`, `lib/xlib/device.nix` |
| Изменить домен / сертификат | `modules/server/coredns.nix` + `modules/server/nginx.nix` (или `vds/`) |
| Sops-секрет | положить в `secrets/<name>.<yaml|json|env|ini>`; `users.nix:99` уже подключает `secrets/default.yaml`; dotenv/json-секреты — через `mkUserSecret` |

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

## Где НЕ лезть без ответа владельца

- `secrets/` (sops-encrypted, расшифровываются `/etc/ssh/id_ed25519` → циклический bootstrap).
- `lдet deploy` без проверки deploy-rs нод: `rydiwo` (ноутбук, может быть выключен).
- Любая правка, противоречащая «Подтверждённым инвариантам» выше.

## Дальше читать

- `docs/arch/map.md` — полная карта: per-host детали, сетевая топология,
  инвентарь сервисов, все известные open questions.
- `docs/arch/invariants.md` — слои 9–11 (home-manager, deploy, формат) +
  полный список неотвеченных вопросов слоёв 1–8.
- `docs/arch/todo.md` — задачи A1–F (правки и документирование).