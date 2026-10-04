# Состояние и следующий шаг (после /compact)

## Где мы
- В `modules/containers/3x-ui.nix`:
  - `patchScript` (костыльник patcher) **заменён** на `migrateScript` — идемпотентная миграция БД, перемещает `publicKey/fingerprint/serverName/spiderX/mldsa65Verify` из nested `realitySettings.settings` в **top-level** `realitySettings`
  - systemd-сервис `patch-3xui-xray-config` **заменён** на `migrate-3xui-reality` (oneshot, after=`podman-3xui_app.service`)
  - **timer удалён** (больше не нужен)
  - Image остался `v3.8.5` (но v3.8.5 и v3.9.0 имеют один баг — раздельные поля на top-level в БД решают)
- Комментарий к image обновлён — объясняет что баг в обоих версиях, лечится миграцией

## Что делать (А → Б → В)

### A. Доразвернуть текущий rebuild
Текущая команда зависла с `nixos-rebuild-switch-to-configuration.service was already loaded` (предыдущий прогон не очистился).
Что сделать:
```bash
sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null
sudo pkill -f switch-to-configuration 2>/dev/null
sleep 3
sudo nixos-rebuild switch
```

### Б. Проверить что миграция работает
После успешного rebuild и старта контейнера:
1. `sudo systemctl status migrate-3xui-reality` — должен быть `inactive (dead)` (success)
2. `sudo journalctl -u migrate-3xui-reality --since 5m` — должно быть `migrated=0` (idempotent, второй раз)
3. `sudo podman exec 3xui_app python3 -c "import json; c=json.load(open('/app/bin/config.json')); ib=c['inbounds'][1]; rs=ib['streamSettings']['realitySettings']; print(rs.get('publicKey','MISSING')[:25])"` — должно быть `K0Ra5yH4Ll_bB-dBmwZcPvYxr`
4. `sudo podman exec 3xui_app python3 -c "import sqlite3,json; c=sqlite3.connect('/etc/x-ui/x-ui.db'); rs=json.loads(c.execute('SELECT stream_settings FROM inbounds WHERE id=53').fetchone()[0])['realitySettings']; print('top publicKey:', 'YES' if rs.get('publicKey') else 'NO'); print('nested settings:', rs.get('settings','NONE'))"` — должно быть `YES` и `NONE`

### В. Итоговый commit
После успешного теста:
```bash
cd /etc/nixos
sudo git add modules/containers/3x-ui.nix
sudo git commit -m "3x-ui: migrate Reality fields to top-level (root-cause fix for panel config-gen bug)"
```

## Контекст
- Container: `ghcr.io/mhsanaei/3x-ui:v3.8.5`, xray 26.9.30
- nginx stream :8443 → podman-proxy :15380 → xray :8443 (ранее подтверждена)
- DB уже мигрирована (поля на top-level) — миграция только идемпотентно проверяет на повторе
- Тест с 5 регенерациями подтвердил: publicKey/fingerprint/spiderX/mldsa65Verify остаются в config.json
- Otreca (VDS) — ssh затянут на tailscale-only, deploy-rs деплоит

## Ключевые файлы
- `/etc/nixos/modules/containers/3x-ui.nix` — NixOS-модуль (требует deploy)
- `/etc/nixos/configurations/vds.nix` — VDS ssh на tailscale (уже закоммичен и задеплоен)
- `/mnt/services/nodes/sapphira/3x-ui/db/x-ui.db` — БД панели (миграция уже применена)
- `/etc/nixos/deploy/default.nix` — deploy-rs конфиг (otreca → vds config)

## Известное замечание
Внутри podman exec bash tool убивает backgrounded процессы. Для тестов с долгоживущим xray-клиентом используй systemd-run --scope или делай inline тесты (без background). Для проверки config.json хватает быстрого `podman exec python3 -c`.
