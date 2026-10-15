# ADR-0005: `herdr.zeroq.su` — за nginx без authelia, только herdr token

**Статус:** accepted

**Дата:** 2026-10-15

**Контекст.**

`herdr-web-ui` (плагин `devswha/herdr-web-ui`, 970★, MIT) — это Bun-сервер на `127.0.0.1:7317`, который рисует web-интерфейс к herdr workspaces/panes/agents: чат agent'а, live terminal, attachments, push-уведомления. Запускается как startup-хук плагина в `herdr-prod` сессии. Включается через `herdr plugin install devswha/herdr-web-ui`.

Vhost в `modules/server/nginx.nix`:
- `proxy_pass http://127.0.0.1:7317` с `WebSocket`-апгрейдом
- forceSSL + ACME на `herdr.zeroq.su`
- Host header rewrite (`proxy_set_header Host $host`)
- Без `auth_request /authelia` (специально)

**Почему НЕ authelia forward-auth (в отличие от `vtimeline.zeroq.su`, `tty.zeroq.su`, `*.zeroq.su` wildcard в `authelia.nix:170`):**

1. **CSRF `sameOrigin()` в `server/machine-security.ts:18-46`.** Функция сравнивает `new URL(request.url).origin` (читается из TCP-назначения `proxy_pass` → `http://127.0.0.1:7317`) с `new URL(headers.origin).origin` (браузер шлёт `https://herdr.zeroq.su`). За любым reverse proxy, кроме Tailscale serve / прямого loopback, эти хосты не совпадают → `403 invalid_origin` на **каждом** cross-origin POST. Функция **не читает** `X-Forwarded-Host` и не имеет env-флага "trust this proxy" (проверено в `server/index.ts:562, 1792, 3607`).
2. **authelia forward-auth ломает POST.** `auth_request /authelia` → 401 для неаутентифицированного → `error_page 401 =302` редирект на authelia login. Redirect работает для GET, но **POST через эту цепочку → 500** ("auth request unexpected status" в nginx error log). `/api/auth` (форма отправки токена) — POST. Исключение `~ ^/api/(auth|devices/pair|health)$` из authelia убирает 500, но CSRF-лимит `sameOrigin` остаётся.
3. **In-place patch в `server/machine-security.ts` (sapphira, `.orig` сохранён) — НЕ upstream-merged.** Добавляет поддержку `X-Forwarded-Host` в `sameOrigin()` при наличии `X-Forwarded-Proto`. Без него обходного пути нет: Tailscale serve (документированный path) требует Tailscale на каждом клиенте; ssh tunnel — manual per device; fork + plugin link — поддержка.
4. **herdr token (`HERDR_WEB_TOKEN`) — sufficient gate для personal tool.** 64 hex chars = 256 бит энтропии, brute-force защищён per-IP и shared-proxy budgets в `server/auth.ts` (`AUTH_FAILURE_BUDGET=5`, `AUTH_BACKOFF_MS=1_000`, doubling до 60s, 1024-entry LRU). Без authelia нет SSO, но token = одноразовый ввод в браузере + cookie на 1 год. На LAN/localhost достаточно; на публичном экспозе — рассмотреть Tailscale поверх.

**Решение:** vhost `herdr.zeroq.su` обслуживает только `herdr_web_token` cookie / `Authorization: Bearer`. Authelia wildcard `*.zeroq.su` (R1.3) его НЕ покрывает (nginx `auth_request` отсутствует в этом vhost). Поведение authelia для остальных vhost'ов (`vtimeline`, `tty`, ...) не меняется.

**Обоснование:**

- Единственная альтернатива, не ломающаяся через 12 часов: Tailscale serve. Требует Tailscale на каждом клиенте + на сервере. Для personal-use-over-LAN избыточно.
- PR в upstream devswha/herdr-web-ui с поддержкой `x-forwarded-host` в `sameOrigin()` — долгосрочно правильно, но создаёт fork-maintenance burden. Задача T29.
- Форк + `herdr plugin link` на локальный форк — компромисс, но лишает обновлений плагина. Можно рассматривать после T29.

**Последствия:**

- **Позитивные:** webui работает; token-only auth прост и достаточен; нет authelia-races.
- **Негативные:**
  - **Maintenance:** in-place patch в `server/machine-security.ts` перезаписывается при `herdr plugin update devswha/herdr-web-ui`. Перед каждым update: `cp server/machine-security.ts.orig server/machine-security.ts && herdr plugin update devswha/herdr-web-ui && patch -p0 < patch.diff` (или просто вручную перенести). **До T29** это регулярная ручная работа.
  - **Нет SSO:** без authelia пользователь вводит токен в браузере вручную (или через `herdr-web-ui` install скрипт, который сразу проставляет cookie).
  - **Rate-limit на token auth только в Bun server:** если vhost когда-нибудь станет публично экспонирован (router port-forward на 443), brute-force защищён только rate-limit'ом Bun (5/адрес, doubling backoff, 1024 LRU). Без дополнительного слоя (fail2ban на nginx, Tailscale ACL) это лучше, чем ничего, но хуже, чем authelia с паролем + 2FA.
  - **Cookie привязан к host'у:** `herdr_web_token` HttpOnly Secure SameSite=Strict, Path=/, Max-Age=1 год. Без domain (по умолчанию host-only). Если пользователь зайдёт через `https://herdr.zeroq.su:8443` (если будет), cookie не отправится — token придётся ввести заново.

**Смежные находки (НЕ часть этого решения, но задокументированы для следующей сессии):**

- `services.nginx.recommendedProxySettings = true` добавляет `include ...-nginx-recommended-proxy_set_header-headers.conf;` в **каждый** `proxy_pass` location. Этот include ставит `Host $host`, `X-Real-IP $remote_addr`, `X-Forwarded-For $proxy_add_x_forwarded_for`, `X-Forwarded-Proto $scheme`, `X-Forwarded-Host $host`, `X-Forwarded-Server $hostname`. **Если в `extraConfig` тоже стоит `proxy_set_header X-Forwarded-Host $host;`**, nginx шлёт заголовок **дважды**: `herdr.zeroq.su, herdr.zeroq.su` (comma-joined). Для функций, которые делают `lastIndexOf(":")` (как наш patch), `fwdHost = "herdr.zeroq.su, herdr.zeroq.su"` → `expected.host = "herdr.zeroq.su, herdr.zeroq.su"` → URL parse fail → 403. **Fix:** НЕ дублировать `proxy_set_header` в extraConfig; полагаться на include.
- `proxyWebsockets = true` ставит `proxy_http_version 1.1` + `proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection $connection_upgrade;` — нужно для `/ws` (live SSE/terminal streams).
- Static assets (`/manifest.webmanifest`, `/sw.js`, `/favicon.ico`, `/assets/*`) **НЕ должны** идти через regex location с authelia-эксемптом — они и так не-authelia-защищены (authelia применяется к `/` prefix, regex match приоритетнее). Проверено.

**Связанные ADR/R1:**

- ADR-0001 (sops) — `HERDR_WEB_TOKEN` хранится в `~/.config/herdr/plugins/config/devswha.herdr-web-ui/env` mode 0600. **НЕ** через sops (runtime-конфиг плагина, не секрет репо). Если когда-нибудь понадобится ротация через sops — отдельный task.
- R1.14 (ADR-0004) — про **systemd unit** name escape. Здесь другая категория: nginx config + sameOrigin CSRF. R1.15 формализует текущее решение (см. `.agent/rules/project-rules.md`).

**Открытые вопросы / будущие правки:**

- **T29:** PR в `devswha/herdr-web-ui` с поддержкой `X-Forwarded-Host` в `sameOrigin()`. После merge этот ADR можно пересмотреть и вернуть authelia перед vhost'ом.
- **Когда (если) роутер пробрасывает 443 на herdr.zeroq.su наружу:** добавить fail2ban на nginx (5/мин threshold) или закрыть публичный экспозе через Tailscale ACL.
- **Если vhost получит второй alias (например, `herdr.lan.zeroq.su`):** вторая секция `virtualHosts` с тем же `proxyPass`, разный `server_name`. Cookie не будет пересекаться (host-only).
