# ADR-0010: `vetymae.webmux.zeroq.su` — публикация webmux через sapphira, вход через Authelia

**Статус:** accepted, **не развёрнут** (правка в рабочем дереве; активация =
`deploy .#sapphira`).

**Дата:** 2026-11-06

**Контекст.**

Запрос владельца: «на текущем хосте должен подняться webmux, на порту 8083.
Нужно сделать реверс прокси через sapphira. `vetymae.webmux.zeroq.su` — vhost».

Состояние на момент запроса (проверено на живом хосте vetymae):

- `C:\Users\oqyude\webmux` — git-клон
  `github.com/samoylenkodmitry/webmux` (коммит `913a559`), **не** npm-пакет
  `webmux` (`windmill-labs/workmux-web` — это другое приложение, «дашборд для
  workmux», и оно в этой задаче не участвует);
- `server.js` — веб-терминал к tmux-сессиям: `GET /api/sessions`,
  `WS /ws/session/<name>`, `WS /ws/new`;
- запущен scheduled task'ом `WebmuxServe`
  (`powershell -NoProfile -WindowStyle Hidden -File run-service.ps1`,
  `HOST=0.0.0.0`, `PORT=8083`, `TMUX_BIN=…\psmux.exe`), task Enabled, триггер
  — Repetition, LogonType=Interactive;
- слушает `0.0.0.0:8083`; `curl http://192.168.1.100:8083/` → 200 (LAN) и
  `curl http://127.0.0.1:8083/` → 200.

То есть сам webmux **уже поднят** и доступен в LAN — не хватало только входа
снаружи.

**Решение.**

Vhost `vetymae.webmux.zeroq.su` в `modules/server/nginx.nix` (sapphira):

- `proxyPass http://192.168.1.100:8083` — LAN-адрес vetymae, **не** tailscale
  `100.86.62.4`: tailscaled на vetymae застрял в NoState с обнулённым
  PrivateNodeKey (узел виден в tailnet, но пакетов не принимает — тот же
  аргумент, что у `vetymae.opencodes.zeroq.su`);
- `proxyWebsockets = true` — терминал стримится по WS, без апгрейда вкладка не
  получит ни байта;
- `proxy_read_timeout/send_timeout 3600s` — дефолтные 60 с рвут
  долгоживущую WS-сессию;
- **Authelia forward-auth** (`auth_request /authelia` + `error_page 401 =302` +
  внутренний `= /authelia` subrequest) — ровно как на `tty.zeroq.su` (ttyd —
  тоже веб-терминал) и `vtimeline.zeroq.su`. Wildcard `*.zeroq.su` в
  `access_control` покрывает домен, правки политики не нужно.

**Почему Authelia, а не голый прокси (главное решение).**

У webmux **нет аутентификации**: его README прямо пишет, что «любой, кто
достучался до порта, получает шелл твоим пользователем», и запрещает
`0.0.0.0` и публичный интернет — безопасным сделано только связывание с
`127.0.0.1` плюс доступ через приватный tailnet. На vetymae `HOST=0.0.0.0`
(это сделано сознательно: nginx живёт на другом хосте и должен достучаться по
LAN). Поэтому публикация без аутентификации = **публичный шелл на Windows-машину
владельца**. Authelia — уже работающая в этом репозитории SSO-обвязка, ровно
с тем же паттерном, что у соседних веб-терминалов.

**Альтернативы и почему не выбраны.**

1. **Голый прокси без auth.** Отклонено: это публичный шелл (см. выше).
2. **nginx `auth_basic` + htpasswd.** Отклонено: в репозитории уже есть SSO
   (Authelia) с готовым forward-auth паттерном; второй механизм аутентификации
   означал бы второй users-database и лишний секрет.
3. **Tailscale Funnel / прокси через tailnet вместо публичного vhost.**
   Отклонено: владелец попросил именно vhost на `zeroq.su`; кроме того,
   tailscaled на vetymae нерабочий (см. выше) — Funnel с vetymae не поднять.
4. **Проксировать через `vetymae.opencodes.zeroq.su` (уже есть vhost на
   vetymae).** Отклонено: это другой апстрим (opencode web-UI) и другой
   порт; смешивать два приложения в одном vhost'е — плохая граница.

**Последствия.**

- Вход требует пароль Authelia; после него cookie на домене `zeroq.su`
  покрывает и `vetymae.webmux.zeroq.su`.
- Терминал отдаётся по HTTPS с сертификатом Let's Encrypt (ACME-01 через
  nginx; wildcard `*.webmux.zeroq.su` в публичном DNS уже есть —
  `vetymae.webmux.zeroq.su → 37.128.246.126`).
- LAN-экспозиция `0.0.0.0:8083` остаётся: любой в домашней сети получает
  шелл без пароля. Это осознанно (иначе nginx с другого хоста не достучится);
  при недоверенной сети `HOST` надо вернуть на `127.0.0.1` и пробрасывать
  иначе.
- **Windows Firewall на vetymao.** До правки с sapphira до `192.168.1.100:8083`
  был **таймаут** (с самой машины — 200): в брандмауэре висели два inbound
  правила `Action=Block` для `C:\users\oqyude\scoop\apps\nodejs\26.13.0\node.exe`
  (профили Private+Public, порт Any), а block-правила в Windows важнее
  allow-правил. Allow-правила существовали только для старых версий node
  (26.5.1 / 26.12.0 / 26.12.1). Сделано: block-правила для 26.13.0
  **отключены** + добавлено узкое правило `webmux inbound TCP 8083`
  (Allow, TCP 8083, только этот node.exe, Private+Public). Итог: для node
  26.13.0 inbound по умолчанию закрыт (DefaultInboundAction=Block), открыт
  только 8083. **При следующем обновлении node через scoop block-правило может
  появиться снова** — тогда webmux отвалится по таймауту с sapphira, лечится
  тем же disable + allow.
- `run-service.ps1` и правка `package.json` в клоне webmux не отслеживаются
  git'ом (в `.gitignore`/untracked) — это локальная обвязка хоста, в
  Nix-репозиторий она не попадает.

**Проверка.**

```bash
# до switch'а: апстрим отвечает
curl -sS -o /dev/null -w '%{http_code}\n' http://192.168.1.100:8083/       # 200
# после switch'а на sapphira:
curl -sS -o /dev/null -w '%{http_code}\n' https://vetymae.webmux.zeroq.su/ # 302 → authelia
# с валидной сессией Authelia:
curl -sS -o /dev/null -w '%{http_code}\n' -b 'authelia_session=…' https://vetymae.webmux.zeroq.su/
```

**Откат.**

Удалить блок `"vetymae.webmux.zeroq.su"` из `modules/server/nginx.nix` и
`nixos-rebuild switch` на sapphira. Ничего больше не меняется: webmux на
vetymae продолжает работать локально.

**Связанное:** `modules/server/nginx.nix`, `modules/server/authelia.nix`
(wildcard `*.zeroq.su` → `one_factor`), `home/modules/opencode-desktop.nix`
(соседний vhost `rydiwo.opencodes.zeroq.su` — там апстрим на tailscale и
своя basic-auth, здесь апстрим на LAN и SSO), ADR-0009, T61.
