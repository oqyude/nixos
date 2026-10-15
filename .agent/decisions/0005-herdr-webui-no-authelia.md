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
  - **Maintenance (in-place patch `server/machine-security.ts`):** патч перезаписывается при любом обновлении source. `herdr plugin update devswha/herdr-web-ui` **не существует** как команда (verified 2026-10-15 — `herdr plugin --help` показывает только `enable|disable|action|log|pane|list|install`). Реальный flow — **git pull + bun build + правка `~/.config/herdr/plugins.json`** (см. ниже «Рабочая maintenance-процедура»). **До T29** это ручная работа на ~10 команд.
  - **Нет SSO:** без authelia пользователь вводит токен в браузере вручную (или через `herdr-web-ui` install скрипт, который сразу проставляет cookie).
  - **Rate-limit на token auth только в Bun server:** если vhost когда-нибудь станет публично экспонирован (router port-forward на 443), brute-force защищён только rate-limit'ом Bun (5/адрес, doubling backoff, 1024 LRU). Без дополнительного слоя (fail2ban на nginx, Tailscale ACL) это лучше, чем ничего, но хуже, чем authelia с паролем + 2FA.
  - **Cookie привязан к host'у:** `herdr_web_token` HttpOnly Secure SameSite=Strict, Path=/, Max-Age=1 год. Без domain (по умолчанию host-only). Если пользователь зайдёт через `https://herdr.zeroq.su:8443` (если будет), cookie не отправится — token придётся ввести заново.

### Рабочая maintenance-процедура (отработана 2026-10-15, переход 79beb36 → 439ad38)

**Шаг 1.** Сохранить текущий (пропатченный) файл — НЕ в `.orig` (там хранится upstream-версия от первой установки), а в `.patched.bak`:

```bash
PLUGIN_DIR=~/.config/herdr/plugins/github/devswha.herdr-web-ui-210f619d6b7b
cp $PLUGIN_DIR/server/machine-security.ts $PLUGIN_DIR/server/machine-security.ts.patched.bak
```

**Шаг 2.** Discard unstaged patch, чтобы git pull не упал:

```bash
git -C $PLUGIN_DIR checkout -- server/machine-security.ts
```

**Шаг 3.** Pull upstream:

```bash
git -C $PLUGIN_DIR pull --ff-only origin main
```

(Если упадёт `cannot pull with rebase: You have unstaged changes` — значит Шаг 2 не сделан.)

**Шаг 4.** Восстановить патч из бэкапа:

```bash
cp $PLUGIN_DIR/server/machine-security.ts.patched.bak $PLUGIN_DIR/server/machine-security.ts
grep -c "x-forwarded-host\|X-Forwarded-Host" $PLUGIN_DIR/server/machine-security.ts  # должно быть ≥1
```

**Шаг 5.** Перебилдить плагин (source обновился, dist — нет):

```bash
cd $PLUGIN_DIR
bun install   # 231 installs, без изменений если зависимости не трогались
bun run build # → новый dist/assets/index-<hash>.js с новым commit'ом в бандле
```

**Шаг 6.** **КРИТИЧНО: обновить `resolved_commit` в `~/.config/herdr/plugins.json`.** Без этого `herdr plugin list` будет показывать СТАРЫЙ коммит, хотя source/dist уже новые. herdr читает manifest из этого JSON, а не из git HEAD плагина:

```bash
python3 -c '
import json, pathlib
p = pathlib.Path("/home/oqyude/.config/herdr/plugins.json")
data = json.loads(p.read_text())
for plugin in data:
    if plugin.get("plugin_id") == "devswha.herdr-web-ui":
        plugin["source"]["resolved_commit"] = "NEW_COMMIT"
        break
p.write_text(json.dumps(data, indent=2))
'
```

**Шаг 7.** Перезапустить herdr:

```bash
systemctl --user restart herdr
sleep 3
herdr plugin list | grep devswha   # → новый коммит
```

**Gotchas (на чём эта процедура обожглась 2026-10-15):**

1. `herdr plugin list` показывает `source.resolved_commit` из `plugins.json`, **НЕ** из `.git/HEAD` и **НЕ** из dist. git pull + bun build обновляют только source/dist. Без шага 6 — `herdr plugin list` врёт.
2. `cp $PLUGIN_DIR/server/machine-security.ts.orig $PLUGIN_DIR/server/machine-security.ts` (как было записано в первой версии этого ADR) — **НЕПРАВИЛЬНАЯ** последовательность: `.orig` это upstream-версия от первой установки, его нужно сохранять, а не использовать для восстановления патча. Правильный бэкап — в `.patched.bak`.
3. `bun install` на свежем pull не делает ничего видимого («no changes»), но `bun run build` обязателен — старый `dist/assets/index-<hash>.js` содержит **захардкоженный** commit SHA от прошлого билда, и без перебилда web UI стартует со старой версией (даже если source новый).
4. После Шага 7 herdr.service должен быть `active (running)` — если `restart` упал, проверить `journalctl --user -u herdr` на предмет «build failed: plugin».

### Runtime prerequisites на NixOS (обязательно для plugin install/auto-start)

herdr-web-ui plugin устанавливается как git clone в `~/.config/herdr/plugins/github/devswha.herdr-web-ui-<hash>/` и при install **сам скачивает bun в свой runtime manager** (path-pattern `~/.local/share/herdr-web-ui/install.<hash>/runtime/bin/bun`). На сапфире plugin уже стоит и работает; на каждой новой машине, где herdr есть, plugin попытается поставить себя автоматически — и на NixOS без этих prerequisite сломается. Три слоя, каждый проявляется после починки предыдущего:

1. **`pkgs.bun` в shell PATH** — для `preflight.sh` plugin'а и для всего окружения, где запускается herdr. Без этого preflight.sh падает с «bun: command not found». Источник: `home/modules/herdr-runtime.nix` (импортируется в `home/server.nix` и `home/secondary.nix`). Системный bun из `/nix/store/...-bun-*/bin/bun` подхватывается home-manager'ом.

2. **`pkgs.nodejs_22` в shell PATH** — preflight.sh плагина проверяет `node --version` (`herdr web ui needs Node 18 or newer for its terminal sidecar`). Без этого preflight падает после прохождения bun-проверки. Источник: тот же `home/modules/herdr-runtime.nix` (добавлен вместе с bun, единый путь).

3. **`programs.nix-ld.enable = true` глобально** — для запуска **собственного** bun плагина (`~/.local/share/herdr-web-ui/install.<hash>/runtime/bin/bun`), который динамически слинкован для generic linux. **Системный bun из пункта 1 НЕ помогает** — plugin использует свой internal runtime manager, а не fallback на PATH. Без nix-ld stub ld получаем «NixOS cannot run dynamically linked executables intended for generic linux environments out of the box» на старте plugin'а. Источник: `modules/essentials/packages.nix` с `stdenv.cc.cc.lib` (glibc + libstdc++ + libgcc_s) — этого минимума достаточно для glibc-based bun.

**Trap, на которую наступили 2026-10-15:** добавление системного bun в PATH **выглядит как** решение («теперь bun есть»), но плагин продолжает скачивать свой runtime, потому что использует **собственный** install manager, а не fallback. Только nix-ld чинит собственно исполнение скачанного бинаря. Документация nixpkgs по `programs.nix-ld`: `https://nix.dev/permalink/stub-ld`.

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
