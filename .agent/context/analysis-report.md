# Analysis Report

## Session

- **Session ID:** `metaagent-init-2026-10-09`
- **Target repo:** `S:/Git/nixos`
- **Date:** 2026-10-09
- **Project type:** `existing` (NixOS-конфиг, 120 `.nix`, ~8.5k строк)

## 1. Общая информация

- **README:** одна строка без смысла (`"I'm a super newbie who just posted my stuff here. Now maybe about intermediate"`); функциональную роль README играет `AGENTS.md` (корень).
- **Лицензия:** не указана.
- **CI/CD:** отсутствует. `nix flake check` — единственная автоматическая защита, прогоняется вручную. `deploy/default.nix:27-29` — `checks = builtins.mapAttrs (... deployChecks)`, но они покрывают только deploy-сценарий.
- **Точка входа:** `flake.nix` → `nixosConfigurations.<attr>` (хосты) + `nixOnDroidConfigurations.<attr>` (Android). Реестр хостов: `configurations/default.nix:13-39`.
- **Система сборки:** Nix + NixOS flakes. Home-manager, sops-nix, disko, deploy-rs, grub2-themes, justray.

## 2. Стек технологий (existing)

| Компонент | Значение |
|---|---|
| Язык | Nix (`.nix`) |
| Фреймворк | NixOS modules + home-manager |
| База данных | PostgreSQL (в `modules/server/postgresql.nix`), sqlite (3x-ui) |
| Тестовый раннер | отсутствует (см. §5) |
| Пакетный менеджер | Nix (`nix flake`, `nix-env`, `nix profile`) |
| Линтер/форматтер | отсутствует (комментарий-density 38/120 файлов без комментариев — открытый вопрос 0.2) |

## 3. Архитектура (existing)

```
flake.nix
├── configurations/         ← реестр хостов (1 запись = 1 машина)
│   ├── default.nix         ← hosts + xlib + mkSystem
│   ├── <host>.nix          ← модульное тело хоста
│   └── hardware/<host>.nix
├── home/                   ← home-manager (per device-type)
├── modules/
│   ├── options.nix         ← кросс-модульные опции
│   ├── default.nix         ← defaultModule + strictModule (для nix-on-droid)
│   ├── essentials/         ← packages, services, settings, ssh, shell, systemd-routines
│   └── <type>/             ← per-type: desktop/, server/, vds/, wsl/, containers/, termux/, other/
├── lib/
│   ├── mkSystem.nix        ← nixosSystem + specialArgs(xlib, inputs)
│   └── xlib/               ← чистые данные: devices, dirs, helpers
├── overlays/, pkgs/, deploy/, secrets/ (sops)
└── .sops.yaml              ← один age-ключ на secrets/<name>.(yaml|json|env|ini)
```

**Паттерн:** модульный монолит с xlib-инъекцией (аналог dependency injection через `specialArgs`).

**Ключевые модули:**

| Модуль | Описание |
|---|---|
| `configurations/default.nix:13-39` | Реестр хостов (7 entries); `mkXlib` в строке 50 |
| `configurations/<host>.nix` | Per-host: имя, тип, импорт модулей; 7 файлов |
| `lib/xlib/default.nix:38-77` | `mkXlib` — единственная точка сборки xlib |
| `lib/xlib/device.nix:12-41` | Закрытое множество device.types: { minimal, primary, secondary, server, vds, wsl, termux } |
| `lib/xlib/helpers.nix` | `mkBindMount`, `mkSystemdBind`, `mkServiceStorage`, `mkNtfsMount`, `mkExfatMount`, `mkTmpDirs`, `mkSymlinks` |
| `modules/options.nix` | Кросс-модульные опции: `host.builder.*`, `host."3x-ui".*` |
| `modules/default.nix:9-39` | `nixosModules.default` — импортируется на каждый NixOS-хост; `nixosModules.strict:40-53` — для nix-on-droid |
| `modules/essentials/` | `packages`, `services`, `settings`, `ssh`, `shell`, `systemd-routines` |
| `modules/users.nix` | Пользователь `oqyude` (uid 1000, sapphira=1001), sops-секреты, hostKey bootstrap |
| `modules/server/` | 20+ системных сервисов sapphira (см. `server/default.nix:imports`) |
| `modules/server/systemd.nix` | rsync oneshots с `requiresMountsFor` guard (единственный пример guard'а) |
| `modules/server/{nginx,coredns}.nix` | Reverse proxy + DNS для зон `zeroq.su` и `home.arpa` |
| `modules/containers/` | podman-контейнеры: 3x-ui (заморожен), tape-rotation, remnanode, kokoro-tts, openhands, remnawave-examples |
| `home/<type>.nix` | Home-manager per device-type; для `root` — без профиля |
| `home/modules/opencode.nix` | OpenCode CLI + systemd user services (см. R2 — `Service` vs `serviceConfig`) |
| `deploy/default.nix` | deploy-rs ноды: sapphira, otreca, rydiwo (НЕ atoridu/wsl/epral) |

## 4. Конвенции (existing)

- **Стиль:** Nix-форматирование, разные отступы в разных файлах (нет единого стандарта).
- **Импорты:** `imports = [ ./foo.nix ./bar.nix ];` или list-spread. `lib.optional` для условных импортов.
- **Типизация:** types из `lib.types` (например, `lib.types.str`, `lib.types.bool`, `lib.types.attrsOf`).
- **Обработка ошибок:** `throw` + literal-сообщения (например, `lib/xlib/device.nix:12-41` — throw со списком валидных типов).
- **Логирование:** не формализовано; rsync oneshots в `modules/server/systemd.nix` — единственный пример с `-v` + structured output.

## 5. Тесты (existing)

- **Команда запуска:** отсутствует. Единственная полуавтоматическая проверка — `nix flake check`.
- **Всего тестов:** 0
- **Пройдено:** N/A
- **Упало:** N/A
- **Пропущено:** N/A
- **Упавшие тесты:** N/A

Кандидаты на CI-проверки (открытый вопрос 11.2):

1. ни одного `:latest` в образах (grep по `image =`)
2. `nix flake check` зелёный — уже ловит A1
3. домены в `coredns.nix` ↔ vhost'ы в `nginx.nix` совпадают в обе стороны
4. для каждого потребителя `mkServiceStorage` каталог существует на `External`
5. последнее правило самописной nftables-цепочки явное
6. `listen.addr` — адрес интерфейса, а не сеть
7. все файлы в `secrets/` матчат `path_regex` из `.sops.yaml`

## 6. Базовая проверка (existing)

- **Сборка:** не проверена в этой сессии (нет `nix` в PATH, AGENTS.md ссылается на `nix flake check`).
- **Запуск:** N/A (NixOS-конфиг, не приложение).
- **Git status:** рабочее дерево было чистым после коммита `7c9aa24` (yaml frontmatter в AGENTS.md). 1 modified файл (AGENTS.md) — fixed.

## 7. Требования (N/A для existing)

## 8. Примечания

- **Проход по репозиторию 2026-10-05**: 120 `.nix`, ~8.5k строк. Подтверждённые
  инварианты (1–6) зафиксированы в `.agent/rules/project-rules.md` (R1).
- **Слои 9–11** (home-manager, deploy, формат) перенесены в `.agent/roadmap/sources.md`
  как открытые вопросы; см. §9.2, §10.1-10.4, §11.1-11.2 исходного `invariants.md`.
- **Шаблон инварианта** (4 оси: Утверждение, Где, Почему, Действие) — для новых
  записей. Обратное: до правки `authelia.nix:51,108,109` шёл через хелпер
  `sopsPath = name: "/run/secrets/${name}"`; `open-webui.nix:95`, `tape-rotation.nix:61`,
  `remnawave.nix:61, 129, 136` — литеральный хардкод. См. ADR-0001.
- **Bootstrap-цикл ключа** (R3) — должен быть задокументирован, иначе при
  переустановке хоста агент не выведет. Открытый вопрос 4.2.
