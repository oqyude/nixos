# 3x-ui: миграция Xray-core 26.7 → 26.9 — что известно

> Дата регресса: 2026-10-04. Цель: зафиксировать всё, что мы нашли про переход
> с ядра 26.7.x на 26.9.x, чтобы будущие сессии не повторяли ту же работу.

## TL;DR

- На ядре **26.7.28** всё работало (последний известный рабочий билд).
- На ядре **26.9.x** REALITY-клиенты не подключаются. Это касается и xray-core
  26.9.8, 26.9.9, 26.9.30.
- В 3x-ui **v3.9.0** (latest, released 2026-10-03) панель поставляется с
  xray-core **26.9.30**. Ядро меняется в UI панели: Settings → Xray version.
- Текущий код в `modules/containers/3x-ui.nix` зафиксирован на **v3.8.5**, но
  в реальности запущен **v3.9.0** (подтянут вручную через `podman pull`,
  см. ниже).

## Как переключать ядро из UI панели

1. Зайти в панель `https://<host>:2049` (или твой реальный хост:порт).
2. Panel Settings → Xray version → выбрать нужный тег (например `v26.7.28`).
3. Save → панель скачает бинарь xray-core из GitHub releases
   `https://github.com/XTLS/Xray-core/releases/download/<tag>/Xray-linux-64.zip`
   в `/app/bin/xray-linux-amd64` и перезапустит xray.
4. Проверить: `podman exec 3xui_app /app/bin/xray-linux-amd64 version`.

В таблице `nodes` БД панели хранится колонка `xray_version` — это то, что
панель показывает как «текущая установленная версия».

## Ключевые изменения в Xray 26.9.x (по сравнению с 26.7.x)

Изменения, которые мы нашли в исходниках, в changelog'е 3x-ui, и в
пользовательских исследованиях (`~/External/Git/temp/xray-research.md`):

### 1. Обязательный постквантовый обмен ключами (X25519MLKEM768)

- Начиная с **xray-core 26.9.8** сервер **требует**, чтобы первый key share
  клиента был X25519MLKEM768 (постквантовый KEM). Если клиент не отправляет
  его первым, соединение разрывается с `authentication failed`.
- Поддержка у клиентов: последние версии xray-core 26.9.x, свежие Mihomo /
  Clash. Старые клиенты ломаются.
- Это само по себе объясняет часть регрессов у пользователей.

### 2. Поведение `minClientVer`

- В 26.7.x при пустом `minClientVer` xray накладывал встроенный минимум
  (примерно 26.3.27). В 26.9.x пустое поле ограничение **не накладывает**.
- Это не баг, но меняет поведение: некоторые клиенты, которые раньше
  проходили по умолчанию, теперь проходят без явной отметки версии.

### 3. Серверный `decryption` и клиентский `encryption`

- На стороне сервера, в `clients[].settings.decryption`, теперь хранится
  спецификация ML-KEM обмена в формате:
  ```
  mlkem768x25519plus.{native|xorpub|random}.{1rtt|0rtt|<seconds>}.<base64>...
  ```
  На стороне inbound валидируется `s[2]` как число секунд (например `600s`),
  на стороне outbound — как `1rtt` или `0rtt`.
- В share-link `vless://` параметр `encryption=...` несёт то же значение в
  клиентском формате (`0rtt`/`1rtt`). Парсеры клиентов должны его понимать.
- См. валидацию в `infra/conf/vless.go::VLessOutboundConfig.Build()` и
  `infra/conf/vless.go::VLessInboundConfig.Build()` в репозитории XTLS.

### 4. Поле `mldsa65Verify` / `mldsa65Seed`

- Это дополнительная постквантовая подпись поверх обычного REALITY (на базе
  ML-DSA-65).
- По умолчанию панель кладёт оба поля в `realitySettings`. В share-link
  они не передаются — клиент их не использует (они серверные).
- Если клиент сам не использует mldsa65Verify, отсутствие поля в share-link
  не блокирует подключение.

### 5. Поле `serverNames`

- Должно быть массивом строк. Панель всегда пишет массив, так что для нас это
  не источник проблем.

## Что нашёл 3x-ui (changelog v3.9.0 vs v3.8.5)

### Главное изменение, влияющее на нас

> «⚙️ **Xray-core v26.9.30** — stored XDNS masks and WireGuard outbound
> settings are migrated to the new core's shape automatically.»

То есть в v3.9.0 панель **обязательно поставляется с ядром 26.9.30**, и при
старте выполняет миграции (XDNS, WireGuard). Про миграцию
`realitySettings.settings` **ничего не сказано**.

### Фиксы v3.9.0, которые теоретически могли бы помочь

- `#6691` — JSON subscriptions for REALITY with Host SNI no longer ship a
  config the client core refuses to start. Это про **подписки**, не про
  **config.json inbound'а**.
- `#6694` — Spider settings in a REALITY spiderX query are kept in share
  links and JSON subscriptions. Тоже про подписки.
- `#6686` — `config.json` is written after a hot apply, so config backups no
  longer upload stale rules. Это про backup, не про сам config-gen.

**Итог**: ни одного исправления бага `GetXrayConfig` для **config.json**
inbound'а нет ни в v3.8.5, ни в v3.9.0.

## Подтверждённый баг: `GetXrayConfig` стирает `realitySettings.settings`

Источник: `internal/web/service/xray.go` в репозитории MHSanaei/3x-ui:

```go
realitySettings, ok2 := stream["realitySettings"].(map[string]any)
if ok2 { delete(realitySettings, "settings") }
```

Панель явно удаляет nested-блок `realitySettings.settings` при каждой
регенерации config.json. Поля, которые там лежат (а их кладёт туда сама же
панель при создании inbound'а в новых билдах):
`publicKey`, `fingerprint`, `serverName`, `spiderX`, `mldsa65Verify`.

После удаления блока эти поля не появляются на top-level `realitySettings`,
поэтому `/app/bin/config.json` отдаётся xray-core без них, и xray не может
завершить REALITY-handshake для inbound'а.

**Воспроизведено** на этой системе: для id=42 и id=50 в
`stream_settings` БД **нет** top-level `publicKey`/`fingerprint`/... —
панель переписывает их обратно в nested-only в течение нескольких секунд
после любого изменения inbound'а.

Тест с маркером `_migration_marker`: записали в `stream_settings` для
id=40 (`enable=0`), через 5 секунд панель его стёрла.

## Перезапись БД панелью — где и когда

Панель перезаписывает `inbounds.stream_settings` для **активных** inbounds
(id=42 и id=50 в нашей системе) при любом из:

- изменении inbound'а через UI / API
- вызове `restartXrayService` API
- периодическом фоновом цикле панели (мы наблюдали в течение секунд)

Disabled inbound (id=40 в нашей системе) панель не трогает.

Это значит, что **миграция БД при старте контейнера не решает проблему**:
после первой же фоновой регенерации панель снова стирает миграцию, и
config.json опять без публичных полей.

## Подтверждённый рабочий workaround (был в HEAD до регресса)

`patchScript` + systemd timer, который каждые 10 с:

1. Читает `/etc/x-ui/x-ui.db` (источник истины для панели).
2. Извлекает значения `publicKey`, `fingerprint`, `serverName`, `spiderX`,
   `mldsa65Verify` для каждого `vless` inbound'а. Предпочитает top-level,
   fallback на nested `settings.{...}`.
3. Читает `/app/bin/config.json` внутри контейнера.
4. Для каждого inbound'а в config.json, матчит по `port` к БД, и если
   каких-то полей нет или они отличаются — вписывает их.
5. Атомарно переписывает config.json (через `os.replace` на
   `config.json.tmp`) — чтобы не было torn-write при гонке с записью
   панели.
6. Шлёт SIGHUP всем процессам `xray-linux-amd64` внутри контейнера, чтобы
   xray перечитал config.json в памяти (без разрыва активных соединений).

Это перекрывает баг панели, потому что правка идёт в **выходной артефакт**
(`/app/bin/config.json`), а не в БД. Панель может писать туда же, но
следующий тик таймера (через ≤10 с) снова всё поправит.

## Регресс кода — что сделано

Файл `modules/containers/3x-ui.nix` откатан к чистому виду:

- `image = "ghcr.io/mhsanaei/3x-ui:v3.9.0"` — соответствует реально
  запущенному контейнеру (latest от 2026-10-03).
- `migrateScript`, `patchScript`, `migrate-3xui-reality.service`,
  `patch-3xui-xray-config.service`, `patch-3xui-xray-config.timer` —
  закомментированы. Никаких внешних патчей config.json из NixOS больше не
  делается.
- Ядро xray-core теперь переключается **только через UI панели**.
- В комментарии к image записано предупреждение про баг `GetXrayConfig` и
  рабочий workaround, чтобы будущие сессии не переизобретали.

## Полезные ссылки

- Changelog 3x-ui v3.9.0: https://github.com/MHSanaei/3x-ui/releases/tag/v3.9.0
- Все релизы 3x-ui: https://github.com/MHSanaei/3x-ui/releases
- Все релизы xray-core: https://github.com/XTLS/Xray-core/releases
- `infra/conf/vless.go` в xray-core — парсинг server-side decryption /
  client-side encryption (`mlkem768x25519plus.*.*.*`).
- `internal/web/service/xray.go` в 3x-ui — `delete(realitySettings, "settings")`,
  источник бага.
- Этот документ — `modules/containers/3x-ui-migration-notes.md`.
- Исследование пользователя — `~/External/Git/temp/xray-research.md`.

## Что делать дальше (когда понадобится)

1. Если после переключения ядра через UI панель работает и xray-core
   показывает `26.7.28` через `podman exec 3xui_app /app/bin/xray-linux-amd64
   version` — все готово, никакого кода менять не нужно.
2. Если панель всё равно ломает config.json даже на 26.7.x (мы не видели
   такого, но возможно после какого-то будущего обновления панели) —
   раскомментировать `patchScript` + service + timer в файле и сделать
   `nixos-rebuild switch`.
3. Если нужна поддержка нескольких ядер одновременно (например, test
   env) — выделить отдельный контейнер с зафиксированной версией через
   `containers."3xui_test"` с отдельным volume на DB.