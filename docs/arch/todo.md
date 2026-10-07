# TODO: правки и инварианты

Источник: `docs/arch/invariants.md`. Ответы владельца от 2026-10-05 учтены.
Подтверждённые факты зафиксированы в `AGENTS.md` (корень) и `docs/arch/map.md`;
этот файл — только **незакрытые правки и неотвеченные вопросы**.
Порядок: A → B → C → D, потом E (документация для агента).

Обозначения: `[ ]` не начато, `[x]` сделано, `[!]` блокирует остальное.

---

## Подтверждено (зафиксировано в `AGENTS.md` / `map.md`)

Эти инварианты уже учтены в ядре и карте — при правке кода опираться на
зафиксированные формулировки.

- **6.1** Явная финальная политика nftables на VDS → `todo A3` ещё открыто,
  но сам «надо запилить» закреплён.
- **6.3** Firewall на sapphira выключен намеренно (граница — роутер, 5 портов:
  22, 80, 443, 8443, 22000) → формулировка в `AGENTS.md §3`, `todo D1`.
- **6.5** `100.64.0.0` = Tailscale-адрес sapphira (назначен вручную) → `AGENTS.md §5`,
  `map.md §Сеть и firewall`.
- **7.1 / 7.2** 3x-ui заморожен: панель на latest, ядро Xray на 26.7.x,
  миграция 26.9 провалена → `AGENTS.md §4`, `todo C1–C5`.

---

## Ловушки для агента: выглядит сломанным, но это намеренно

Прежде чем чинить — проверить этот список. Здесь лежат решения, которые
иначе «поправляются» обратно и ломают рабочую систему.

| Где | Что выглядит ошибкой | На самом деле |
|---|---|---|
| `configurations/server.nix:130` | `networking.firewall.enable = false` на сервере с 20 сервисами на `0.0.0.0` | Намеренно: фильтр на роутере, он пробрасывает 5 портов (см. D1) |
| `configurations/mobile.nix:95`, `wsl.nix:59` | `stateVersion` 24.05 / 24.11 против 26.05 у остальных | Каждый хост зафиксирован на своей версии; не «подровнять» |
| `modules/users.nix:66` | `uid = if hostname == "sapphira" then 1001 else …` с пометкой TODO | Осознанный костыль под старый uid 1000 = `yuyus`; удалять только после миграции ФС |
| `modules/containers/3x-ui.nix:54` | `image = …:latest` | Панель намеренно на последней версии; **ядро** Xray — на 26.7.x, миграция на 26.9 провалена |
| `modules/containers/3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS при откате nginx-stream | Следствие отката `c8d4a12`; смысл утрачен, но опция объявлена — см. C5 |
| `modules/server/default.nix:33-47` | 15 закомментированных модулей с живым кодом | Отключены осознанно; см. E3 |
| `modules/server/{mealie,memos,n8n,netdata,nfs,open-webui,rsync,step-ca,transmission,trilium,zerotier}.nix` | Агент насчитает лишние порты и каталоги | Модули вне `imports` = мёртвый код |
| `home/modules/opencode.nix:339` | `systemd.user.services.opencode-web.Service` вместо привычного `serviceConfig` | `serviceConfig` рендерится в секцию `[serviceConfig]`, которую systemd **молча игнорирует** (`c73a698`) |
| `configurations/vds.nix:73-91` | nftables без финального правила | Известный пробел,см. A3 — **не** «случайно потерялось» |
| `100.64.0.0` в `nginx.nix`, `nextcloud.nix`, `vds/*` | Первый адрес CGNAT `/10`, похож на сетевой | Tailscale-адрес sapphira, назначен вручную |
| `server.nix:61-63` | `z /mnt/services 0777` | World-writable точка монтирования; см. B1 |

---

## A. Блокеры: сломано или не защищено

### [ ] A1. `mobile.nix` импортирует несуществующий файл

**Где:** `configurations/mobile.nix:12`
```nix
xlib = import ../lib/xlib.nix { lib = inputs.nixpkgs.lib; };
```
Файла `lib/xlib.nix` нет — есть каталог `lib/xlib/` с `default.nix`.
**Правка** (как в `configurations/default.nix:5`):
```nix
xlib = import ../lib/xlib { inherit lib; };
```
**Следствие:** до правки `nixOnDroidConfigurations.epral` и `.default`
не вычисляются. Устройство `epral` мертво.
**Проверка:**
```
nix eval --raw .#nixOnDroidConfigurations.epral.config.environment.etcBackupExtension   # ожидается .bak
```

### [ ] A2. Убедиться, что `nix flake check` вообще запускается

**Где:** нет CI; `checks` в `deploy/default.nix:27-29` покрывают только deploy.
**Сначала проверить**, ловит ли текущий `nix flake check` поломку из A1:
```
nix flake check
```
Ожидание, которое надо подтвердить: он **уже падает** на `epral`, то есть
проверка существует, но её не запускали. Если падает — A1 и был бы замечен.
**Проверка после A1:** та же команда должна стать зелёной.
**Затем** (E2) — превратить в привычку: прогонять перед каждым коммитом.

### [ ] A3. Явная финальная политика nftables на VDS

**Где:** `configurations/vds.nix:73-91`
**Сначала диагностика на otreca** (без неё править опасно — можно отрезать SSH):
```
nft list ruleset
systemctl status nftables firewall-nftables
```
Нужно понять, кто реально владеет набором правил: `nftables.enable = true` с
собственным ruleset **и** `networking.firewall.*` включены одновременно
(инвариант 6.2). Затем — править **один** механизм, не оба.
**Что должно получиться** (политика — на выбор владельца, два варианта):
```
# Вариант «белый список» (предпочтительно):
chain input {
  type filter hook input priority 0; policy drop;
  iif lo accept
  ct state established,related accept
  iif "tailscale0" accept
  tcp dport { 80, 443 } ct state new limit rate 20/second burst 40 packets accept
  tcp dport { 22 } ct state new accept          # только если 22 нужен на ens3
}
# Вариант «мягкий» (минимум изменений, фиксирует текущее поведение):
chain input {
  type filter hook input priority 0;
  iif lo accept
  ct state established,related accept
  tcp dport { 80, 443 } ct state new limit rate 20/second burst 40 packets accept
  tcp dport { 80, 443 } ct state new drop
  # финал accept — но ТОЛЬКО как явно помеченное «разрешено всё остальное»:
  iif "ens3" accept comment "PROVISIONAL: explicit allow-all, см. A3"
}
```
**Инвариант к записи:** последнее правило самописной цепочки всегда явное.
**Проверка:** `nft list chain inet filter input` + `ssh` с внешнего адреса.

---

## B. Защита данных

### [ ] B1. Guard на несмонтированный носитель `/mnt/services`

**Где:** `lib/xlib/helpers.nix` (`mkServiceStorage`), потребители —
`modules/server/{postgresql,n8n,samba,homebox,minecraft}.nix` + `modules/containers/3x-ui.nix`
**Проблема (подтверждена владельцем как не продуманная):** `mkServiceStorage`
даёт `bind,x-systemd.automount,nofail`. Если диск `External` (`xlib.dirs.server-home`,
ext4 по UUID, `configurations/server.nix:55-58`) не смонтирован, то `/mnt/services`
— обычный каталог, `/var/lib/<service>` пуст, и сервис **молча** стартует на чистой
базе. Пользователь увидит «потерялись данные».
**Решение (рекомендую):** добавить в `xlib/helpers.nix`
```nix
mkStorageGuard =
  { dir }:
  {
    # сервис не стартует, пока /mnt/services не смонтирован:
    # Requires+After на mnt-services.mount, который упадёт, если нет источника
    requiresMountsFor = [ dir ];
  };
```
и в каждом потребителе:
```nix
systemd.services.postgresql = xlib.helpers.mkStorageGuard { dir = xlib.dirs.services-mnt-folder; };
```
**Важно — не проверять `ConditionPathIsMountPoint=/mnt/services`:** bind-mount
внутри одной ФС не меняет `st_dev`, условие вернёт false даже при корректном
монтировании. Надёжны `requiresMountsFor` или `ConditionPathIsMountPoint` на
`xlib.dirs.server-home` (там `st_dev` действительно другой).
**Плюс операционная строка в `AGENTS.md`:** перед рестартом этих сервисов —
`findmnt /mnt/services`.
**Проверка (имитация отказа):**
```
systemctl stop postgresql
sudo umount /mnt/services            # или остановить automount
systemctl start postgresql           # ожидается FAIL, а не пустая база
```

### [ ] B2. Зафиксировать, что бэкапов в конфигурации нет

**Где:** `modules/server/postgresql.nix:23` (`postgresqlBackup.enable` закомментирован),
бэкап-сервиса в репозитории нет вообще; БД 3x-ui — sqlite на том же диске.
**Задача — не код, а запись:** в `AGENTS.md` и `invariants.md` явно сказать,
что бэкапы ведутся вне Nix. Иначе агент считает конфиг самодостаточным.
**Ждёт ответа:** где бэкапы и как их проверять (инвариант 5.6).

---

## C. 3x-ui: заморозить рабочее состояние

### [ ] C1. Вернуть расследование, потерянное при откате

**Где:** 200 строк удалены коммитом `22a19be`.
**Восстановить и дополнить выводом:**
```
git show 9974784:modules/containers/3x-ui-migration-notes.md > docs/arch/notes/3x-ui-xray-26.9.md
```
Дописать в конец: вердикт — миграция ядра 26.7 → 26.9 **провалена**, откат на
рабочее состояние (панель последняя, ядро 26.7.x), обходные скрипты отключены
осознанно; причина отказа — обязательный постквантовый обмен X25519MLKEM768,
ломающий старых клиентов.
**Инвариант:** откат кода не удаляет расследование; заметка живёт в
`docs/arch/notes/`, а не рядом с откатываемым файлом.

### [ ] C2. Зафиксировать фактические версии панели и ядра

**Где:** `modules/containers/3x-ui.nix:54`
**Сначала узнать, что реально работает** (на sapphira и на otreca):
```
podman images --format '{{.Repository}}:{{.Tag}}  {{.Id}}  {{.Created}}' | grep 3x-ui
podman inspect ghcr.io/mhsanaei/3x-ui --format '{{index .RepoDigests 0}}'
podman exec 3xui_app /app/bin/xray-linux-amd64 version
```
**Потом** заменить `:latest` на найденный тег (или digest) в коде.
**Инвариант:** образы контейнеров запинены; `latest` запрещён — обновление
образа это правка в коде, а не `podman pull` на хосте.
**Почему срочно:** `podman.autoPrune.flags = ["--all"]` (`3x-ui.nix:45-47`) +
`:latest` = рабочее состояние может смениться без единого коммита.

### [ ] C3. Убрать сервис автообновления 3x-ui

**Где:** `modules/containers/3x-ui.nix:80-90` (`podman-update-3xui_app` с
`podman pull … :latest`) и закомментированный таймер (строка 97-103).
**Предложение:** удалить сервис целиком, оставив комментарий-предупреждение.
Обновление панели через `pull` — ровно тот путь, которым в 2026-10-04
декларация разошлась с рантаймом; автоматизировать его нельзя.
**Инвариант:** ни один контейнер в этом репозитории не обновляется сам.

### [ ] C4. Записать в AGENTS.md, что ядро Xray — состояние панели, а не Nix

Версия ядра выбирается в UI панели и лежит в её sqlite-БД, то есть **вне** Nix.
Репозиторий не может её гарантировать.
**Операционное правило:** перед деплоем/рестартом 3x-ui проверять версию ядра
в панели; обновление ядра = отдельная задача с записью в
`docs/arch/notes/`, а не молчаливый `podman pull`.

### [ ] C5. Решить судьбу `reality443Forwarding`

**Где:** `modules/vds/default.nix:19` (`= true`), `modules/options.nix:66-75`,
`modules/containers/3x-ui.nix:33-35`.
Состояние после отката `c8d4a12`: опция включена, поэтому на otreca
пробрасывается `127.0.0.1:15380:443`, тогда как единственный Reality-инбаунд
контейнера слушает 8443, а публичный 8443 проброшен напрямую (`0.0.0.0:8443`).
Потребителя потока (nginx-stream) откат убрал.
**Варианты:** (а) оставить как есть и описать в инвариантах; (б) погасить опцию
в `vds/default.nix` и убрать её из `options.nix`; (в) довести до рабочего
состояния. **Ждёт решения** — связано с 6.9.

---

## D. Сетевая граница: записать то, чего нет в репозитории

### [ ] D1. Пробросы роутера — главный недостающий инвариант

Ответ владельца: на сервер пробрасываются **443, 80, 22000 (syncthing),
8443 (xray), 22 (ssh)**. Это **настоящая граница доверия**, и она живёт
в конфиге роутера, то есть вне репозитория.
**Записать в двух местах:** `docs/arch/invariants.md` (слой 6) и `AGENTS.md`.
Формулировка инварианта:
> Экспозиция наружу определяется пробросами на роутере, не `openFirewall`.
> На `sapphira` `networking.firewall.enable = false` намеренно.
> Список пробросов: 22, 80, 443, 8443 (3x-ui/Xray REALITY), 22000 (syncthing).
> Новый сервис не становится доступен из интернета, пока не добавлен проброс.
> `networking.firewall.*` на `sapphira` не имеет эффекта.

### [ ] D2. Зафиксировать `100.64.0.0` как Tailscale-адрес sapphira

Моё прежнее замечание («сеть вместо адреса») было неверным — адрес назначен
вручную. Записать как факт + список из 4 мест, которые придётся править при
смене: `modules/server/nginx.nix`, `modules/server/nextcloud.nix`,
`modules/vds/systemd.nix`, `modules/vds/nginx.nix`.
**Опционально (отложено):** вынести `192.168.1.20` в `xlib.dirs` — сейчас
зашит в ~30 местах в 6 файлах. Не срочно, это рефакторинг.

### [ ] D3. Убрать мёртвое правило firewall

**Где:** `modules/server/nginx.nix:225-228` — `allowedTCPPorts = [80 443]`
не действует при `firewall.enable = false` (`server.nix:130`).
Удалить или пометить комментарием «депенит от D1».

---

## E. Документация для агента (после прохода по invariants.md)

### [ ] E1. Написать `AGENTS.md` в корне
Собирается из подтверждённых инвариантов. Структура: карта хостов →
что где лежит → инварианты (нарушишь = сломает) → ловушки из таблицы выше →
команды проверки. Ожидаемый бюджет — до 150 строк.

### [ ] E2. Выбрать проверки, которые заменят половину инвариантов
Кандидаты из инварианта 11.2:
1. ни одного `:latest` в образах (grep по `image =`);
2. `nix flake check` зелёный — уже ловит A1;
3. домены в `coredns.nix` ↔ vhost'ы в `nginx.nix` совпадают в обе стороны;
4. для каждого потребителя `mkServiceStorage` каталог существует на `External`;
5. последнее правило самописной nftables-цепочки явное;
6. `listen.addr` — адрес интерфейса, а не сеть;
7. все файлы в `secrets/` матчат `path_regex` из `.sops.yaml`.
**Ждёт ответа:** какие из них делать, какие — избыточны.

### [ ] E3. Судьба 15 закомментированных модулей
`modules/server/default.nix:33-47` — `remnawave, coturn, mealie, memos,
minecraft, n8n, netdata, nfs, open-webui, rsync, step-ca, stirling-pdf,
transmission, trilium, zerotier`. Удалить или оставить как референс?
Они мешают агенту насчитывать порты и каталоги, которых нет.

---

## F. Ждут ответа (блокируют E1)

Индексы в `docs/arch/invariants.md`:

| № | Вопрос, который блокирует запись инварианта |
|---|---|
| 2.2 | `vetymae` / `lamet` / `therima` / `soptur` — это те же машины или хосты вне репозитория? |
| 2.5 | `stateVersion` дрейфует 24.05 / 24.11 / 25.05 / 26.05 — намеренно? |
| 2.6 | Есть ли escape hatch для per-host отличий в `xlib`, или «у всех хостов одно» — закон? |
| 3.2 | `any.nix` (minimal) действительно нуждается в home-manager + sops + disko? |
| 4.1 | Как root получает доступ по SSH — `authorizedKeys` для root в коде нет |
| 4.2 | Как разрешается цикл «ключ `/etc/ssh/id_ed25519` лежит внутри секрета, а нужен для расшифровки» |
| 4.3 | Что лежит в `secrets/`, все ли файлы покрыты `path_regex` |
| 4.4 | Как подключается вторая машина / второй человек при одном age-ключе |
| 4.5 | `users.nix:87` — личный ключ или общий «ключ от деплоя» |
| 5.1 | `/mnt/services` в режиме 0777 — осознанно? |
| 5.3 | NFS выключен, Samba работает — миграция? |
| 5.4 | NTFS-том `lamet-drive` с `mask = "0000"` — что на нём лежит |
| 5.5 | `therima` / `vetymae` / `soptur` — несуществующие остатки или сетевые шары |
| 5.6 | Где бэкапы БД и 3x-ui (→ B2) |
| 6.6 | `192.168.1.20` зашит в 30 мест — считаем константой? |
| 6.7 | DNS дублирует инвентарь сервисов — как проверяем рассинхрон |
| 6.8 | Публичные IP и SSH-алиасы в `home/termux.nix` — карта «хост → адреса» нужна? |
| 6.9 | Какой путь REALITY считается правильным (→ C5) |
| 7.4 | Почему не публиковать весь диапазон 14380-15379 |
| 8.2 | `lamet.opencodes` → `:6061` — это miniflux; ошибка или так задумано |
| 8.4 | `onlyoffice` — работает после трёх регрессов? |
| 8.5 | Что слушает `:3002` (`/whiteboard` в nextcloud) |
| 9.2 | Кто создаёт `~/Music` и `~/Storage` при `createDirectories = false` |
| 10.1 | Почему `deploy-rs` не деплоит `atoridu`, `wsl`, `epral` |
