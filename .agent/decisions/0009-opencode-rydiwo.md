# ADR-0009: OpenCode на rydiwo — desktop-адаптация под `rydiwo.opencodes.zeroq.su`

**Статус:** accepted, **не развёрнут** (правка в рабочем дереве; активация =
`nixos-rebuild switch --flake .#rydiwo` на rydiwo + `nixos-rebuild switch
--flake .#sapphira` для vhost'а).

**Дата:** 2026-11-06

**Контекст.**

Запрос владельца: «адаптируй opencode под rydiwo, размести его под vhost
`rydiwo.opencodes.zeroq.su`. По плагинам — всё так же, как на vetymae;
sapphira уже адаптировано, но там headless, в отличие от rydiwo».

В репозитории к этому моменту есть **два** разных «opencode-хоста» и
**три** разных конфига, и их нельзя смешивать:

| хост | device | opencode | конфиг | GUI |
|---|---|---|---|---|
| `vetymae` | Windows 11, 192.168.1.100 | 2.0.32, вручную | `~/.config/opencode/opencode.jsonc` | полный (Windows-десктоп) |
| `sapphira` | server, 192.168.1.20 | 2.0.32, `home/modules/opencode.nix` | Nix | headless |
| `rydiwo` | secondary, Chuwi MiniBook | — | — | Plasma 6 / Wayland |

`sapphira` — единственный opencode, описанный в Nix. Но он **headless**:
opencode там существует только как systemd user service, отдающий web-UI
через nginx (`opencode.zeroq.su`), и GUI-инструменты (browser-control,
computer-use) там бессмысленны. `vetymae` — эталон конфигурации, но он
Windows и в Nix не описан.

Фактический конфиг vetymae (`~/.config/opencode/opencode.jsonc` +
`oh-my-opencode-slim.json`, прочитаны 2026-11-06):

- плагин: `oh-my-opencode-slim@3.0.5` (единственный, кто умеет v2);
- дефолтная модель: `opencode-go/deepseek-v4.1-flash`;
- MCP-серверы: `webpage` (**выключен**, `disabled: true`), `browser-control`,
  `computer-use`, `genoffice`;
- авто-одобрение прав: 6 правил `permissions` (external_directory, read,
  edit, bash, webfetch, websearch — все `allow`, resource `*`);
- скилл `browser-control` в `~/.config/opencode/skills/browser-control/`.

**Решение.**

Новый модуль `home/modules/opencode-desktop.nix` (импортируется в
`home/secondary.nix`, т.е. только на `rydiwo`) + vhost
`rydiwo.opencodes.zeroq.su` в `modules/server/nginx.nix` (sapphira).

1. **Плагин и конфиг — как на vetymae.** `oh-my-opencode-slim@3.0.5`, те же 5
   агентов с `opencode-go/deepseek-v4.1-flash`, тот же дефолт модели, те же
   6 правил `permissions`, `webpage` — выключен.
2. **Плюс browser-control MCP** — единственный GUI-MCP, переносимый на
   NixOS: Node-сервер + расширение для Chromium, которым управляет
   пользователь в своей сессии. Версия зафиксирована
   (`@opencode-ai/browser-control@0.8.4`); пакет ставится через `npx`
   (паттерн репозитория, см. `webpage-mcp` на sapphira) + прогрев npx-кеша
   на активации, иначе первый спавн не влезает в MCP-таймаут startup (30 с).
   Из того же npm-пакета на активации копируются SKILL.md (в
   `~/.config/opencode/skills/browser-control/`) и распакованное расширение
   (в `~/.local/share/opencode/browser-control-extension/`).
3. **`opencode serve` как systemd user service** на `0.0.0.0:4096`,
   `--cors https://rydiwo.opencodes.zeroq.su`, пароль — из sops-окружения
   `~/.config/opencode/server.env` (тот же механизм, что на sapphira).
   Фоновый сервис v2 выключен (`service.json: disabled`), CLI ходит в юнит
   через обёртку `oc`.
4. **vhost на sapphira** проксирует на **tailscale-адрес**
   `100.92.238.19:4096`.

**Что НЕ перенесено и почему.**

- **`computer-use` MCP** — инструмент только под Windows: `pywinauto` /
  `comtypes` / UI Automation (`opencode-computer-use` 0.1.2,
  github.com/rwarx/opencode-computer-use, описание прямо говорит «for
  Windows»). Linux-порта нет; своя реализация потребовала бы отдельного
  стека управления X11/Wayland (ydotool/xdotool + portal RemoteDesktop +
  захват экрана + OCR) — это отдельная задача, а не побочный эффект
  «адаптации opencode».
- **`genoffice` MCP** — CLI из поставки Electron-приложения GenOffice для
  Windows; публичного npm-пакета нет (`npm view genoffice` → 404),
  официальной Linux-сборки тоже нет. GenOffice вообще не портирован на
  Linux.

**Решение владельца (2026-11-06):** `browser-control` остаётся, «остальное
пока не будем ставить» — то есть `computer-use` и `genoffice` сознательно
вне объёма этой задачи, а не «не успели». Главное, ради чего делалось:
rydiwo — полноценная нода наравне с sapphira (opencode web + свой vhost),
а не «полу-DNS-запись».

**Инцидент на первой пересборке rydiwo (2026-11-06, 15:11).**

`home-manager-oqyude.service` упал:

```
ln: failed to create symbolic link
  '/home/oqyude/.config/opencode/opencode.json': Permission denied
→ home-manager-oqyude.service: status=1/FAILURE
```

Причина — **не** в модуле opencode, а в общем механизме sops-nix: он
создаёт отсутствующие каталоги-родители секретов **от root** (0755
root:root) и **не меняет владельца уже существующих**. На rydiwo секреты
opencode появились раньше home-manager (13.10 против 06.11), поэтому
`~/.config/opencode` и `~/.local/share/opencode` остались `root:root` —
и home-manager не смог создать в них свои файлы (второй каталог важен и
для самой БД `opencode.db`). На sapphira те же каталоги создал
home-manager (как пользователь) — там sops-nix ничего не сломал, но тот
же класс граблей повторился бы, если бы каталог когда-нибудь удалили.

sops-nix не умеет менять владельца каталога-родителя, поэтому фикс —
в активации системы: `system.activationScripts.opencodeSecretDirs` в
`modules/users.nix` (root, снипет после `users`, то есть до старта
`home-manager-<user>.service`). Владелец каталогов меняется на
`<user>:<group>`; `chown`/`install` идут через `|| echo`, потому что у
activate-скрипта ERR-trap и падение сделало бы активацию проваленной
при уже переключённой системе.

Разблокировка без пересборки (сделано вручную 15:18): `chown` двух
каталогов + `systemctl restart home-manager-oqyude.service` → активация
прошла, `opencode-web.service` поднялся, `opencode plugin list` показал
`oh-my-opencode-slim 3.0.5`, web-UI отдал 200, MCP `browser-control`
заспавнился.

Плюс в этом же заходе: `timeout 600`/`timeout 900` на прогрев плагина и
npx-кеша в `home/modules/opencode-desktop.nix` — зависшая загрузка не
должна держать активацию (и пересборку) намертво.

**Открытый пункт: провайдер `opencode-go` на rydiwo.** Реестр моделей
берётся из `GET https://opencode.ai/console/api/v2/config`, и этот запрос
требует OAuth-учётку интеграции `opencode` — она лежит в БД opencode
(таблица `credential`, тип `oauth`: access/refresh/expires). На rydiwo её
нет ⇒ реестр = только встроенный `opencode`, и агенты slim-плагина
(`opencode-go/deepseek-v4.1-flash`) упадут с `ProviderModelNotFoundError`
(ровно тот класс граблей, что в R1.19). Проверено: с sapphira тот же
endpoint отдаёт 200 с OAuth-токеном и **без** прокси — то есть внешний
доступ не при чём, нужен именно логин. На rydiwo `opencode auth list`
→ «No authenticated integrations».

**Обоснование.**

- **Отдельный модуль, а не переработка `home/modules/opencode.nix`.**
  Работающий opencode владельца (sapphira) — не то место, где стоит
  рефакторить ради нового хоста: правка не может быть проверена прогоном
  (юнит живёт на сервере), а цена ошибки — сломанный агент владельца.
  Дублирование ~150 строк Nix обменивается на изоляцию: правка rydiwo
  физически не может изменить поведение sapphira.
- **Tailscale-адрес, а не LAN.** LAN-адрес rydiwo (`192.168.1.102`) — это
  DHCP-lease, и он **уже один раз уезжал** на другую машину (LAMET — это
  видно из `~/.ssh/config` на vetymae и из комментария в
  `configurations/mini-laptop.nix`). Tailscale-адрес стабилен; проверено с
  sapphira 2026-11-06: `tailscale ping 100.92.238.19` → direct, 26 ms.
  (Заодно это чинит потенциальную дыру: `configurations/server.nix:157`
  до сих пор указывает engipy-backend на `192.168.1.102` — тот самый
  DHCP-адрес; это отдельная задача, здесь не трогаем.)
- **Без egress-прокси, в отличие от sapphira.** На sapphira `opencode.ai`
  недоступен напрямую (TCP timeout), и юнит ходит через 3x-ui-egress на
  `127.0.0.1:10808`. На rydiwo маршрут есть: проверено на живом хосте
  2026-11-06 — `GET https://opencode.ai/console/api/v2/config` отвечает
  (401 без токена — то есть маршрут и TLS есть, нужен только токен).
  Прокси на rydiwo неоткуда брать: 3x-ui там нет.
- **`--port 4096` задан явно.** Дефолт `opencode serve` в v2 — 4097 (4096
  занят фоновым сервисом v2). Без флага vhost отдаёт 502 без ошибок в
  логах — ровно та ловушка, что описана в R1.19.
- **`--hostname 0.0.0.0`, а не только tailscale-адрес.** Слушать только
  `100.92.238.19` нельзя: локальный `oc` ходит на `127.0.0.1:4096`, и при
  падении tailscale локальный TUI перестаёт работать. Наружу (LAN, а при
  ноутбуке — любой Wi-Fi) opencode отдаётся под basic-auth из sops-файла;
  файрвол на хосте выключен (граница — LAN), как и на остальных хостах
  флота.
- **Chromium добавлен в `home.packages`.** browser-control управляет
  ВИДИМЫМ браузером пользователя; на rydiwo браузера не было вообще, то
  есть без него MCP был бы мёртвым. Расширение подгружается вручную
  (unpacked, режим разработчика) — это шаг, который Nix не может сделать
  за пользователя.

**Альтернативы и почему не выбраны.**

1. **Рефакторинг `home/modules/opencode.nix` в общий модуль с параметрами
   хоста.** Отклонено: трогает рабочий и проверенный opencode владельца на
   сервере; выигрыш — меньше дублирования, цена — риск для агента, который
   владелец использует каждый день.
2. **Отдельный `home/rydiwo.nix` вместо импорта в `home/secondary.nix`.**
   Отклонено: `home/secondary.nix` — это и есть «home для device.type =
   secondary», ровно один хост (rydiwo). Отдельный файл добавил бы
   параллельную точку входа без выигрыша.
3. **Плагин `browser-control` как opencode-плагин (а не MCP).** Отклонено:
   пакет публикует MCP-сервер (`dist/mcp.js`) и CLI, а не opencode-плагин;
   в `plugins` класть нечего.
4. **Ставить `@opencode-ai/browser-control` в Nix-стор через
   `buildNpmPackage`.** Отклонено (пока): у пакета нет lock-файла, сборка
   тянет ~10 MB playwright-core и требует сети на этапе `npm install`;
   паттерн `npx` + прогрев кэша уже применён в этом репозитории
   (`webpage-mcp`) и даёт тот же результат. Герметичный вариант — отдельная
   задача, если `npx` начнёт мешать.
5. **Пробросить GUI-доступ rydiwo в sapphira иначе (например, SSH-туннель
   в обратную сторону).** Отклонено: rydiwo сам держит opencode, туннель
   нужен только для эгреса, а он не нужен (см. выше).

**Последствия.**

- На rydiwo появляется opencode 2.0.32 (~170 MB в кэше плагина), Chromium
  (~400 MB) и `opencode.db` в `~/.local/share/opencode/`. БД растёт (на
  vetymae доходила до 9.5 GB) — **не** класть её на `/mnt/lamet`: это NTFS,
  а SQLite на NTFS даёт риск повреждения. Следить за размером.
- Юнит `opencode-web` на rydiwo живёт без графической сессии (linger=1 в
  `modules/users.nix`), т.е. web-UI доступен всегда; browser-control при
  этом работает с браузером, запущенным пользователем в сессии.
- Локальный TUI: `oc` в терминале rydiwo подключается к тому же юниту
  (`--server http://127.0.0.1:4096`) — это то, чего на headless sapphira
  нет.
- Ничего не меняется в поведении sapphira: её `home/modules/opencode.nix`
  не тронут.

**Проверка.**

```bash
# на rydiwo
systemctl --user status opencode-web              # active, 0.0.0.0:4096
opencode plugin list                              # oh-my-opencode-slim 3.0.5
ss -lntp | grep 4096
curl -sS -u opencode:"$OPENCODE_SERVER_PASSWORD" http://127.0.0.1:4096/api/health

# с sapphira
curl -sS -u opencode:"$OPENCODE_SERVER_PASSWORD" https://rydiwo.opencodes.zeroq.su/ | head -5
tailscale ping 100.92.238.19                      # direct

# DNS
dig +short rydiwo.opencodes.zeroq.su              # 37.128.246.126 (wildcard CNAME)
```

**Откат.**

Удалить импорт `./modules/opencode-desktop.nix` из `home/secondary.nix` и
vhost `rydiwo.opencodes.zeroq.su` из `modules/server/nginx.nix`, затем
`nixos-rebuild switch` на обоих хостах. Данных нет, состояния нет —
откат полный. Файл `~/.local/share/opencode/browser-control-extension/` и
конфиг opencode на rydiwo остаются как есть (не управляются Nix после
отката; удалить вручную при необходимости).

**Связанное:** `home/modules/opencode-desktop.nix`, `home/secondary.nix`,
`modules/server/nginx.nix`, `modules/users.nix` (sops-окружение opencode +
linger), `home/modules/herdr-runtime.nix` (bun/nodejs в PATH), R1.19,
ADR-0006 (v2-ловушки), T60.
