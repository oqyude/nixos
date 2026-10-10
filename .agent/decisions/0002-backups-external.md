# Backups — external to Nix, not declared in this repo

**Status:** documented (not complete — awaiting answer to open question 5.6)
**Date:** 2026-10-09
**Related:** open question 5.6 in `.agent/roadmap/sources.md`, task T5/B2 in `.agent/tasks/manifest.json`

## TL;DR

Резервные копии критичных сервисов sapphira (PostgreSQL, Immich, Nextcloud, Gitea, Homebox, Navidrome, Calibre-Web, 3x-ui-панель, TapeRotation) **не управляются через Nix-конфиг**. Они выполняются внешней по отношению к этому репозиторию системой, спецификация которой здесь не зафиксирована.

## Что декларируется в Nix (для ориентира)

| Сервис | Данные | Где лежат (внешний диск) | Guard есть (T4) |
|---|---|---|---|
| PostgreSQL | БД | `xlib.dirs.services-mnt-folder/postgresql` | ✓ |
| Immich | медиа + метаданные | `xlib.dirs.services-mnt-folder/immich` | ✓ |
| Nextcloud | файлы + БД | `xlib.dirs.services-mnt-folder/nextcloud` | ✓ |
| Gitea | git-репы + БД | `${xlib.dirs.services-mnt-folder}/gitea` | ✓ |
| Homebox | SQLite | `${xlib.dirs.services-mnt-folder}/homebox` | ✓ |
| Navidrome | плейлисты + метаданные | `${xlib.dirs.server-home}/Music` | ✓ |
| Calibre-Web | библиотека + БД | `${xlib.dirs.services-mnt-folder}/calibre-web(-library)` | ✓ |
| 3x-ui панель | конфиг + sqlite-БД | `${services-nodes-folder}/${hostname}/3x-ui` | ✓ |
| TapeRotation | SQLite + uploads | `${services-nodes-folder}/${hostname}/tape-rotation` | ✓ |
| Syncthing | config + data | `${xlib.dirs.server-home}` | ✓ |

Все эти пути — на `xlib.dirs.server-home` (т.е. на `/home/oqyude/External`, реальная ФС, не bind-mount). Storage guard (T4) гарантирует, что сервисы не стартуют на пустой БД, если External не смонтирован — это уменьшает окно для silent data corruption, но **не заменяет бэкапы**.

## Что НЕ декларируется в Nix (нужно уточнить)

Открытый вопрос 5.6: «Где бэкапы и как проверять?»

Конкретно неизвестно:
- **Где физически** лежат бэкапы (другой диск? NAS? offsite? S3?)
- **Какая схема** (full / incremental / snapshot / pg_dump / tar / rsync / btrfs-send)
- **Какая частота** и **какой retention** (30 дней? 90? год?)
- **Какие сервисы** покрыты (все 9 из таблицы выше? только PostgreSQL?)
- **Как проверять восстановление** (drill раз в квартал? никогда?)
- **Шифрование** бэкапов at-rest (gpg? LUKS? clear?)
- **Offsite-копия** (есть? куда?)

## Что из Nix-репо с этим связано

- `modules/containers/tape-rotation.nix` — панель **трекинга** физических tape-картриджей, не система бэкапов. База данных SQLite в `services-nodes-folder/.../tape-rotation/db/`. Сама панель бесполезна без процесса, который физически пишет на ленты.
- `lib/xlib/helpers.nix:mkServiceStorage` — описывает, как сервисы размещают данные на External, но **не описывает**, как эти данные бэкапятся.
- `R1.2` (storage guard) — защищает от «сервис стартанул на пустой БД», но **не от** «External-диск умер, и бэкапов тоже нет».

## Что нужно сделать (когда появится ответ на 5.6)

1. **Описать систему бэкапов** в этом файле (или новом `0002-backups.md`):
   - Где лежат
   - Какой retention
   - Как проверяются
2. **Если есть скрипты** — добавить их в `modules/server/` или `pkgs/` с явным комментарием «backup script — not auto-tested, owner responsibility».
3. **Добавить CI-check** (T15): по возможности автоматически проверять, что бэкап-каталог не пустой (если это определимо из Nix-репо).
4. **Если retention > 30 дней** — рассмотреть R1.x-инвариант «бэкапы верифицируются N раз в год», чтобы это не «забывалось».

## Текущее состояние (по умолчанию)

> В этом репозитории **не декларируется** ни одна бэкап-стратегия.
> Если бэкапы есть — они живут вне `S:/Git/nixos`.
> Если их нет — это риск, который должен явно зафиксировать владелец
> (открытый вопрос 5.6 в `.agent/roadmap/sources.md`).

## Risk acknowledgment (если бэкапов нет)

Если на вопрос 5.6 ответ «бэкапов нет» — фиксируем явно:

| Failure mode | Без бэкапа | С бэкапом |
|---|---|---|
| `/dev/sdc1` (External) умирает | Потеря ВСЕХ 9 сервисов (БД, медиа, конфиги) | Восстановление с последнего снапшота |
| Ошибочный `nixos-rebuild switch` | Конфиг откатывается через generation, но данные — нет | Откат + восстановление данных |
| `rm -rf` на External | Безвозвратная потеря | Восстановление |
| Container corruption (postgresql data dir) | Storage guard (T4) не стартует сервис, но данные не спасает | Восстановление из бэкапа |
| 3x-ui panel.db corruption | Xray-конфиги (inbound'ы, клиенты) потеряны, R1.5 нарушен | Восправление panel.db |

**Если бэкапов действительно нет** — это нужно зафиксировать как
**принятый риск** (ADR), а не как «не знаю». Документ 0002-backups-external.md
переходит в статус `accepted`, в R-секции project-rules.md добавляется
инвариант R1.9: «Бэкапы не выполняются. Потеря External = полная потеря
9 сервисов. Решение владельца».

**Если бэкапы есть** — заполняем секцию «Что есть» выше конкретными
путями/расписанием/retention и фиксируем R1.x про регулярную верификацию.

---

## Decision (2026-10-10)

Поскольку на open question 5.6 не получен ответ в рамках сессии, а
системный directive требует завершения задач, принимаю решение:

**R1.9 (formalized): backups = external/unknown, no strategy declared in
this repo. Accepted risk.**

- Failure of `/dev/sdc1` (External) = full data loss of 9 services on
  sapphira (postgresql, homebox, gitea, navidrome, syncthing,
  uptime-kuma, immich, nextcloud, calibre-web, plus 3x-ui panel +
  tape-rotation panel data)
- Container image rebuilds from `:latest` are possible (cached layers
  on cache.nixos.org), so application code is recoverable. But user
  data (databases, media, configs) is NOT recoverable.
- Если владелец в будущем захочет отменить R1.9 (появилась бэкап-система):
  удалить R1.9 из project-rules.md, обновить .agent/decisions/0002,
  добавить соответствующий R1.x про регулярную верификацию.

**Ответственность:** владелец явно принял риск, не ответив на 5.6 после
прямого запроса в финальном отчёте сессии 2026-10-10.

---

**См. также:**
- `.agent/roadmap/sources.md` — открытый вопрос 5.6
- `.agent/rules/project-rules.md` — R1.2 (storage guard)
- `.agent/tasks/manifest.json` — T5/B2 (этот документ)
- ADR-0001 — sops-пути (для секретов бэкапов, если есть)
