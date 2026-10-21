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
   `uptime-kuma`, `immich`, `nextcloud`, `calibre-web`, `3x-ui`, `tape-rotation`
   — **но гвард, который это должен обеспечивать, МЁРТВ.**
   `mkStorageGuard` (`lib/xlib/helpers.nix:180-189`) возвращает ровно одно
   поле, `ConditionPathIsMountPoint = [ xlib.dirs.server-home ]`, а это
   директива секции **`[Unit]`**. Все 12 потребителей передают её через
   `serviceConfig`, поэтому она рендерится в `[Service]`, где systemd её
   **не читает**. Проверено на sapphira 2026-10-15 построчным чтением
   отрендеренных юнитов: у `gitea` секция `[Service]` начинается со строки 5,
   а `ConditionPathIsMountPoint` лежит на строке 14. Надёжный признак — само
   наличие директивы в `[Service]`, а не номера строк: они зависят от состава
   `[Unit]` и меняются при каждом перерендеривании.
   `RequiresMountsFor` в хелпере **нет намеренно**, это не упущение: он
   создаёт зависимость, по которой systemd сам монтирует ФС при старте
   юнита, и это обессмысливает гвард (проверено на sapphira 2026-10-10,
   комментарий `helpers.nix:181-187`). Порядок должен выражаться через
   `After=` на `.mount`-юнит в самом потребителе.
   Гвард мёртв на **13 юнитах / 12 сервисах**: `postgresql`, `samba`,
   `homebox`, `gitea`, `navidrome`, `syncthing`, `uptime-kuma`, `immich`,
   `nextcloud`, `calibre-web`, `3x-ui` (`podman-3xui_app`), `tape-rotation`
   (два юнита: `podman-taperotation-backend` и `podman-taperotation-frontend`).
   Из `gitea-runner` гвард **убран осознанно**: он охранял пустое множество,
   у живого раннера ноль дескрипторов на внешнем диске
   (`modules/server/gitea-runner.nix:143-157`). Цена решения: ничто не
   разделяет старт Gitea на пустой БД и CI-раннер, который затем погонит
   джобы по этой БД. Закрывается только через T4. → задача T4, ADR-0004.
   **Отдельно:** более ранний вывод «`serviceConfig` не мержится с upstream»
   — **ложный**, с правильным ключом он мержится штатно. Проблема в секции,
   а не в мерже. Не ссылаться на «`serviceConfig` мержить нельзя».
3. **Сетевая граница sapphira — роутер.** `firewall.enable = false` намеренно.
   Роутер пробрасывает ровно 5 портов: **443, 80, 22000 (syncthing),
   8443 (xray), 22 (ssh)**. `nginx.nix` (networking.firewall) `allowedTCPPorts`
   мёртв (T13). `openFirewall`/`allowedTCPPorts` на sapphira не имеют эффекта.
4. **`100.64.0.0` = Tailscale-адрес sapphira**, назначен вручную. Не сеть, не
   ошибка. Используется в `home/termux.nix:256`, `modules/server/nextcloud.nix:80`
   (`trusted_proxies`), `modules/server/nginx.nix:109,253`,
   `modules/vds/systemd.nix:10`. При смене — править 4 файла.
5. **3x-ui: версии панели и ядра зафиксированы, обновление — только с записью.**
   Панель: образ запинен на `ghcr.io/mhsanaei/3x-ui:v3.10.2`
   (`modules/containers/3x-ui.nix:54`). До 2026-10-20 был `:latest` — это был
   вектор **тихого дрейфа**: 2026-10-14 релиз v3.10.x притащил ядро Xray
   **26.10.10** вместо 26.7.x, минуя все инварианты (R1.8). Ядро ставится
   через UI панели (Panel Settings → Xray version) и **различается по хостам**:
   **otreca — 26.7.28** (выбран руками), **sapphira — 26.10.10** (дефолт
   бандла v3.10.2, никогда не пинился). «Миграция 26.7.x → 26.9.x провалена»
   держалась на **неверном диагнозе** — см. R1.16 и
   `.agent/decisions/notes/3x-ui-xray-26.9.md`. Обходные скрипты (timer,
   migrateScript) отключены осознанно. **Не** обновлять ядро или панель без
   записи в `decisions/` или `notes/`.
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
   ядра в панели. Nix декларирует панель (теперь запинен на `v3.10.2`,
   R1.5), но не ядро. **Проверять на каждом хосте отдельно:** otreca —
   26.7.28, sapphira — 26.10.10 (2026-10-20). Бандл панели = ядро, которое
   окажется в контейнере, если ядро не выбрано руками в UI.
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
14. **Имя атрибута `systemd.services.<…>` при переопределении upstream-модуля
    должно совпадать ПОБАЙТОВО.** `services.gitea-actions-runner` (nixpkgs)
    регистрирует юнит не через `systemd.services.<имя>`, а через
    `nameValuePair "gitea-runner-${escapeSystemdPath name}"`. `escapeSystemdPath`
    превращает `-` в **литеральную строку `\x2d`**, поэтому для
    `name = "ci-sapphira"` настоящий ключ — `gitea-runner-ci\x2dsapphira`, где
    между `ci` и `dsapphira` стоит обратный слэш, а не дефис. Обе формы
    рендерятся в **один и тот же файл** `gitea-runner-ci-sapphira.service`, но
    это **два разных атрибута**. Репозиторий писал неэкранированное
    `gitea-runner-ci-sapphira` и получал фантомный юнит без `ExecStart`; фантом
    выигрывал рендер, и systemd отказывался стартовать: `Service has no
    ExecStart=, ExecStop=, or SuccessAction=. Refusing.` Юнит молчал **12 часов**
    (2026-10-14 16:25 → 2026-10-15 01:23), система при этом собиралась и
    переключалась без единой ошибки.
    **Последствие для диагностики:** `systemctl show gitea-runner-ci-sapphira`
    возвращает **значения по умолчанию**, а не реальные: looked-up имя не
    совпадает с реальным. Проверять состояние юнита только **чтением файла
    юнита**, никогда `systemctl show` с неэкранированным именем. Проверка на
    фантом (`grep -i` найдёт обе формы, если они одновременно в `attrNames`):
    ```bash
    nix eval --raw .#nixosConfigurations.sapphira.config.systemd.services \
      --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' \
      | grep -i gitea-runner
    ```
    `escapeSystemdPath` недостижим через `lib.utils` в этом флейке, поэтому
    ключ записан литералом (`unitKey`, `modules/server/gitea-runner.nix:15`) и
    разъедется при переименовании. Страховка — `assertions`, падающая на
    отсутствии `ExecStart` (`gitea-runner.nix:196-213`).
    Правило из ADR-0004, а вместе с ним и предупреждение о методе: баг
    пережил **три неверных диагноза подряд** (`a807701`, `e6e82b8`, переход на
    `unitConfig`), и каждый закреплял его, а не лечил. Теория, повёрстая в
    документ, перестаёт проверяться. Прежде чем записать в R1 «причина X»,
    отличить «юнит неполный» от «фантом затеняет юнит»: отсутствие
    `ExecStart=` при `nix build` без ошибок = второе.
15. **`herdr.zeroq.su` — за nginx без authelia, только herdr token.** Vhost
    в `modules/server/nginx.nix` (текущая редакция — 9bf9407) обходит
    authelia forward-auth. Причины: (а) `authelia` subrequest → `error_page 401
    =302` редирект работает для GET, но **POST через эту цепочку → 500**; (б)
    `sameOrigin()` в `server/machine-security.ts:18-46` upstream-версии
    `devswha/herdr-web-ui` сравнивает `new URL(request.url).origin` (видит
    `http://127.0.0.1:7317`, TCP-назначение `proxy_pass`) с браузерным
    `Origin: https://herdr.zeroq.su` — за reverse proxy (кроме Tailscale
    serve) они не совпадают → 403 `invalid_origin` на **каждом** cross-origin
    POST. Исключение `~ ^/api/(auth|devices/pair|health)$` из authelia
    убирает 500, но 403 на `sameOrigin` остаётся. Подробности в ADR-0005.
    **Maintenance:** до T29 (PR в upstream `devswha/herdr-web-ui` с
    поддержкой `X-Forwarded-Host` в `sameOrigin()`) в `server/machine-security.ts`
    sapphira держится **in-place patch**, перезаписывается при
    `herdr plugin update`. Перед каждым update: `cp
    $PLUGIN_DIR/server/machine-security.ts.orig $PLUGIN_DIR/server/machine-security.ts`
    и переустановка патча. **Auth model:** `herdr_web_token` cookie /
    `Authorization: Bearer`, 256 бит энтропии, rate-limit в
    `server/auth.ts:18-28,53-71` (5/адрес, doubling backoff до 60s, 1024
    LRU). Без authelia нет SSO — токен вводится в браузере вручную при
    первом визите или прописывается через `install.sh` (cookie на 1 год).
    На LAN/localhost достаточно; на публичном экспозе добавить fail2ban
    или закрыть через Tailscale ACL.
    **NixOS gotcha:** `services.nginx.recommendedProxySettings = true`
    добавляет `include ...-nginx-recommended-proxy_set_header-headers.conf;`
    в каждый `proxy_pass` location, который ставит `Host $host`,
    `X-Forwarded-Proto $scheme`, `X-Forwarded-Host $host`. Если в
    `extraConfig` ещё раз поставить `proxy_set_header X-Forwarded-Host
    $host;`, nginx шлёт заголовок **дважды** (`herdr.zeroq.su,
    herdr.zeroq.su`) → `sameOrigin` patch видит comma-joined host → URL
    parse fail → 403. **Не дублировать** `proxy_set_header` в
    `extraConfig`; полагаться на include.

16. **REALITY: fingerprint клиента должен быть `chrome`/`firefox`/`safari`.**
    Ядро Xray **>= 26.9.8** (`XTLS/reality` commit `8cdf7bf9c7`) требует, чтобы
    ClientHello содержал key share `X25519MLKEM768` **и** шёл он раньше
    опционального `X25519`. Отдают его только uTLS-отпечатки **chrome,
    firefox, safari**. У `qq`, `edge`, `ios`, `randomized` — нет.
    **Отказ молчаливый:** сервер считает клиента неавторизованным и проксирует
    TLS в реальный сайт-декoy -> клиент получает настоящий сертификат ->
    `REALITY: received real certificate (potential MITM or redirection)` ->
    `REALITY: processed invalid connection`. Итог: **TCP соединяется, TLS
    «успешен», трафика нет**, в панели без ошибок. Проверено 2026-10-20 на
    sapphira: `fp=chrome` -> `uConn.Verified: true` + HTTP 204 через прокси;
    `fp=qq`/`edge`/`ios`/`randomized` -> `verified: false`, трафика нет.
    Править надо **все** инбаунды и **все** исходящие (`panelOutbound`,
    `telegram-edge-of-truth`): fingerprint лежит в
    `realitySettings.settings.fingerprint` (nested-блок, только клиентские
    поля) и попадает в ссылку/подписку оттуда. Плюс `minClientVer`: на 26.7.x
    пустое значение = встроенный пол 26.3.27 (отсекает sing-box/Hiddify — они
    рапортуют 1.8.1 — и Mihomo) -> ставить **`1.0.0` явно**. На >= 26.9.8
    пустое значение = «любая версия», пол снят.
17. **WARP на otreca: `domainStrategy: forceipv4` обязателен.** Аутбаунд
    `warp` (WireGuard/Cloudflare) лежит в `settings.xrayTemplateConfig`
    (не в Nix) и резолвит пир `engage.cloudflareclient.com:2408` в IPv6
    первым. В контейнере podman **нет IPv6-маршрута** -> `bind send err >
    write udp [::]:...->[2606:4700:d0::a29f:c001]:2408: sendto: network is
    unreachable` -> весь трафик, попадающий под правило роутинга в `warp`
    (`geosite:google`, `geosite:meta`, `geosite:apple`, `geosite:openai`,
    `geosite:netflix`, `geosite:spotify`, `geosite:reddit`, `regexp:.*[.]ru$`,
    `regexp:.*[.]su$`), умирает. Лечится `"domainStrategy": "forceipv4"` в
    `settings` аутбаунда `warp` (`infra/conf/wireguard.go`: `forceipv4` ->
    `DeviceConfig_FORCE_IP4`). **Симптом-обманка:** REALITY-хендшейк проходит,
    `uConn.Verified: true`, но трафика нет — XHTTP-POST уходит в ответ,
    которого не будет никогда. Проверка: `curl -x socks5h://127.0.0.1:<порт>
    https://www.google.com/generate_204` через ноду (google = warp-маршрут) vs
    `https://api.ipify.org` (не warp).

18. **(R1.19) OpenCode на sapphira — v2, порт запинен, плагин только
    v2-совместимый, model id — только из реестра.** → ADR-0006.
    **Пакет:** `nixos-unstable` даёт `opencode 1.19.0` (v1). v2 (2.0.32) есть
    только в **nixpkgs master** (PR #569770, влит 2026-10-19) ⇒
    `programs.opencode.package = (import inputs.nixpkgs-master { system = …; })
    .opencode`; `flake.lock` обновлён на `c4f353ac` (2026-10-21). Когда v2
    попадёт в nixos-unstable — вернуть `pkgs.opencode` и снять master-input.
    **Порт:** дефолт `opencode serve` в v2 — **4097** (4096 зарезервирован под
    фоновый сервис v2; проверено на живом бинаре: `server listening on
    http://127.0.0.1:4097`). nginx-vhost `opencode.zeroq.su` проксирует на
    `127.0.0.1:4096` ⇒ `--port 4096` обязан быть в `web.extraArgs` **явно**;
    без него — 502 на проде без единой ошибки в логах opencode. `opencode web`
    в v2 **удалён**; `opencode serve` отдаёт и API, и web-UI.
    **Плагин:** v2-совместим только `oh-my-opencode-slim` (в пакете 3.0.5 есть
    `dist/tui2.js` + `dist/v2/tui.d.ts` + док «OpenCode v2 Compatibility»);
    `oh-my-openagent` 5.1.40 экспортирует только `.`/`./server`/`./tui` —
    v2-точки входа нет ⇒ под v2 не включается. Конфиг slim-плагина лежит в
    `~/.config/opencode/oh-my-opencode-slim.json` (не в `~/.omo/omo.jsonc` —
    это конфиг openagent).
    **Model id — только из реестра:** `opencode models` на обоих хостах
    отдаёт ровно `minimax-coding-plan/MiniMax-M3` (variants none/thinking),
    `minimax-coding-plan/MiniMax-M3.1-Flash` (без variants),
    `opencode/big-pickle` (без variants), `opencode/minimax-m3.1-flash-free`
    (variants low…max). `MiniMax-M3.1-Flash-Preview`, `MiniMax-M2.7-highspeed`,
    `MiniMax-M2.5-highspeed` в реестре **нет** ⇒ `ProviderModelNotFoundError`
    (тот же класс, что kimi-for-coding). Сверять через `opencode models`, а не
    по вкусу.
    **Фоновый сервис v2 выключен** (`~/.config/opencode/service.json` =
    `{"disabled": true}`): иначе CLI поднимает второй сервер на 4096
    (конфликт с юнитом + два писателя в один `opencode.db`). Клиент ходит в
    работающий юнит через обёртку `oc` (= `opencode --server
    http://127.0.0.1:4096`).
    **Данные:** `~/.local/share/opencode/opencode.db` (SQLite) растёт (на
    рабочей машине 9.5 GB); на sapphira `/` свободно ~14 GB ⇒ держать в
    голове перенос `XDG_DATA_HOME` на `/mnt/services`.
    **HM-модуль `programs.opencode` — v1-only:** пишет `opencode.json` +
    `tui.json`, ключ `plugin` (ед. ч.), MCP плоской картой, а `validateFiles.tui`
    берёт `passthru.jsonschema.tui`, которого в v2-пакете **нет** ⇒ валидацию
    tui выключить, конфиг писать руками (`xdg.configFile`).
    **Три «тихих» ловушки v2, найденные на деплое 2026-10-21 (ADR-0006):**
    **(а)** v2 **не ставит пакеты плагинов при старте сервера** — грузит только
    то, что уже в `~/.cache/opencode/npm`. На свежем хосте: `plugin list` пуст,
    агентов slim-плагина нет, его MCP (context7, gh_grep) не появляются, **в
    логах ни строки об ошибке**. Отсюда `home.activation.installOpencodePlugin`
    (`opencode plugin add <spec>` — идемпотентно, ошибки глушатся).
    **(б)** MCP через `npx -y -p <pkg>`: первый запуск качает ~200 МБ и
    handshake не дожидается ⇒ `webpage: failed / Request timed out`; плюс
    остаток кэша от v1 ⇒ `npm ENOTEMPTY`. Отсюда
    `home.activation.warmWebpageMcp` + чистка `~/.npm/_npx/<hash>`.
    **(в)** CLI к работающему серверу: `--server` принимается **после**
    подкоманды (`opencode <cmd> --server <url>`), и нужен пароль (HTTP basic)
    ⇒ обёртка `oc` читает его из sops `server.env`.

### R2. home-manager `Service` ≠ `serviceConfig`

Живой код — `home/modules/opencode.nix:354-359`:
`systemd.user.services.opencode-web.Service = { MemoryHigh = "1G";
MemoryMax = "2G"; OOMScoreAdjust = -900; OOMPolicy = "continue"; };`.
В home-manager нельзя писать `serviceConfig = { ... }` — рендерится литеральная
секция `[serviceConfig]`, которую systemd молча игнорирует
(«Unknown section 'serviceConfig'. Ignoring.»). Правильно:
`systemd.user.services.<name>.Service`. В home-manager cgroup-опции
(`MemoryHigh`, `MemoryMax`, `OOMScoreAdjust`, `OOMPolicy`, …) пишутся в
`systemd.user.services.<name>.Service`, **не** в `serviceConfig`. Ошибка
не диагностируется — она просто не применяется.
**Баг исправлен в `c73a698`**; предупреждение о возврате стоит комментарием в
`opencode.nix:403-406`. Правило остаётся живым как запрет на регрессию:
ошибка не диагностируется и повторяется легко.
Вариант без правильного имени ключа не существует: в системных юнитах тот же
приём срабатывает, только если атрибут совпадает с тем, что upstream отдал
`nameValuePair` (см. R1.14).

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

18. **Правка инбаунда в UI панели НЕ перегенерирует `config.json` и НЕ
    перезапускает xray с новым конфигом.** Панель пишет `config.json` только
    (а) при старте контейнера и (б) по `POST /panel/api/server/restartXrayService`.
    `POST /inbounds/update/:id` меняет только БД и делает *перезапуск xray со
    старым файлом*. Отсюда — «панель показывает новое, сервер крутит старое».
    Особенно опасно для REALITY: UI при сохранении **перегенерирует ключи**
    (новый `mldsa65Seed` -> новые `shortIds`, новый `publicKey`, `mldsa65Verify`
    может обнулиться), а сервер продолжает слушать со старым `privateKey` и
    старыми `shortIds` -> ссылки из подписки не работают, ошибок в панели нет.
    Порядок после любой правки инбаунда:
    1) `POST /panel/api/server/restartXrayService` на хосте, где крутится inbound;
    2) для удалённой ноды — дождаться node-sync и сделать (1) **на ноде**
       (панель-контроллер её `config.json` не трогает);
    3) переподписаться на подписку: ссылки генерируются из БД контроллера,
       а сервер крутит свой `config.json` — они обязаны совпасть;
    4) проверка — клиентский xray с параметрами из ссылки -> HTTP 204.
    Проверено 2026-10-20 на otreca: правка «edge of truth» в UI сменила ключи
    в БД, `config.json` остался от 23:51 -> трафика нет; после
    `restartXrayService` на ноде -> 5/5 успешных попыток.

## Ловушки (выглядит сломанным, намеренно)

Прежде чем чинить — проверить этот список. Здесь лежат решения, которые
иначе «поправляются» обратно и ломают рабочую систему.

| Где | Что выглядит ошибкой | На самом деле |
|---|---|---|
| `server.nix:130` | `firewall.enable = false` при 20 сервисах на `0.0.0.0` | Роутер фильтрует, см. R1.3 |
| `mobile.nix:95`, `wsl.nix:59` | `stateVersion` 24.05 / 24.11 vs 26.05 | Каждый хост зафиксирован на своей версии |
| `users.nix:66` | `uid = if hostname == "sapphira" then 1001 else …` | Костыль под 1000 = удалённый `yuyus`; удалять только после миграции ФС |
| `3x-ui.nix:54` | Раньше `image = …:latest` | **Запинено** на `v3.10.2` (R1.5). `:latest` был вектором тихого дрейфа: релиз панели молча притащил ядро 26.10.10 и сломал все REALITY-ссылки (R1.16). Ядро Xray — состояние панели, см. R1.8 |
| `3x-ui.nix:33-35` | `reality443Forwarding = true` на VDS | **Обязательно, НЕ удалять** (R1.10). nginx stream (`vds/nginx.nix`) маршрутизирует `443 → 127.0.0.1:15380 → container:443`; без маппинга Xray REALITY мёртв. Удаление T10/C5 сломало — восстановлено `07a0437` |
| `vds/nginx.nix`, `events {}` | Пустой блок → `worker_connections` = **512** (дефолт) | Не баг, но и не запас: при окне недоступности REALITY клиенты дают ретрай-флуд и исчерпывают 512 → «не работает всё» даже после починки первопричины (2026-10-10: 1668 ошибок за ~40 мин). Известный пробел, задача не заведена |
| Настройки панели, `webBasePath = /pubray/` | `GET https://pubray1.zeroq.su/` → **404, 0 байт** | Панель жива, корень не корень. Реальный URL — `https://pubray1.zeroq.su/pubray/` (HTTP 200). `/subs/` без токена тоже 404 — это норма. Не «чинить» nginx под `/` |
| `modules/server/default.nix:7-44` | Комментарий-блок на строках 38-41 выглядит как «список отключённых модулей» | T16 **завершена**, закомментированных импортов **0**. Состав: `archive/server-modules/` — 12 файлов (coturn, mealie, memos, minecraft, n8n, netdata, nfs, rsync, step-ca, transmission, trilium, zerotier); `archive/containers/` — `remnawave.nix`, `kokoro-tts.nix`, `openhands.nix`; `stirling-pdf.nix` удалён в `5dd7a58` (поглощён `bentopdf.nix`); `open-webui.nix` не комментировался никогда, переехал в `modules/containers/` и активен (импорт на строке 9) |
| `home/modules/opencode.nix:407` | `systemd.user.services.opencode-web.Service` | **Правильный** паттерн, не баг. Файл и ссылка на строку 339 устарели: баг `serviceConfig` был и **исправлен** в `c73a698`, верная строка 407. R2 удерживает от возврата |
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
5. Проверить, что `config.json` **свежее** БД: сравнить mtime файла и
   время последней правки инбаунда; при расхождении —
   `POST /panel/api/server/restartXrayService` (R1.18). Правка REALITY в UI
   перегенерирует ключи и shortIds, сервер до рестарта крутит старые.
6. Проверить `fingerprint` и `minClientVer` в `x-ui.db` -> `inbounds` ->
   `stream_settings` -> `realitySettings` (клиентские поля лежат в
   `realitySettings.settings`, серверные — на верхнем уровне): `fingerprint`
   должен быть **chrome/firefox/safari**, `minClientVer` — **1.0.0** (R1.16).
   Значения `qq`/`edge` + ядро >= 26.9.8 = «соединяется, трафика нет».
7. Проверить, что WARP-аутбаунд не мёртв: `journalctl -u podman-3xui_app |
   grep -c 'network is unreachable'` -> ожидаем 0. Иначе трафик по warp-правилам
   роутинга умирает (R1.17).
8. Только если 1–7 зелёные, а пользователь всё ещё видит отказ — проблема
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
