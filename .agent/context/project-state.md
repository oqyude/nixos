# Project State
# Auto-generated — updated by ANALYSE (initial) and METASTATE (on updates)

**Last updated:** 2026-10-09T20:30
**Session:** metaagent-init-2026-10-09

## Project Type

`existing` — NixOS-конфиг домашнего флота. 7 host-outputs (6 NixOS + 1 nix-on-droid).

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Nix |
| Framework | NixOS modules + home-manager |
| Database | PostgreSQL (sapphira), sqlite (3x-ui) |
| Test runner | none — `nix flake check` is the only guard |
| Package manager | Nix (flakes) |
| Linter/formatter | none |

## Current Architecture

Модульный монолит с xlib-инъекцией. `flake.nix` → `nixosConfigurations.<attr>` через `configurations/default.nix`. Каждый хост получает `xlib` (identity + dirs + helpers) через `specialArgs` в `lib/mkSystem.nix`. `modules/default.nix` импортирует `nixosModules.default` (все NixOS) или `nixosModules.strict` (только nix-on-droid).

```
configurations/  → 7 хостов (default, atoridu, rydiwo, otreca, sapphira, wsl, epral)
modules/         → essentials + per-type (desktop/server/vds/wsl/containers/termux)
home/            → home-manager per device-type
lib/xlib/        → чистые данные (devices, dirs, helpers)
deploy/          → deploy-rs ноды: sapphira, otreca, rydiwo
secrets/         → sops, один age-ключ
```

## Key Modules

| Module | Status | Description |
|--------|--------|-------------|
| `configurations/default.nix` | existing | Реестр хостов + `mkXlib` |
| `lib/xlib/default.nix` | existing | `mkXlib` — единственная точка сборки xlib |
| `modules/default.nix` | existing | `defaultModule` (NixOS) + `strictModule` (nix-on-droid) |
| `modules/options.nix` | existing | Кросс-модульные опции |
| `modules/users.nix` | existing | Пользователь + sops + hostKey bootstrap |
| `modules/essentials/ssh.nix` | existing | openssh + hostKey |
| `modules/server/{nginx,coredns}.nix` | existing | Reverse proxy + DNS (`zeroq.su`, `home.arpa`) |
| `modules/server/postgresql.nix` | existing | PostgreSQL + `mkServiceStorage` (нужен B1 guard) |
| `modules/server/systemd.nix` | existing | rsync oneshots с `requiresMountsFor` |
| `modules/containers/3x-ui.nix` | frozen | Панель :latest, ядро Xray 26.7.x |
| `home/<type>.nix` | existing | Per-type home-manager |
| `home/modules/opencode.nix` | existing | OpenCode CLI + systemd user (см. R2) |
| `deploy/default.nix` | existing | deploy-rs: sapphira, otreca, rydiwo |

## Hosts

| Attr | hostname | device.type | deploy | stateVersion | Примечание |
|---|---|---|---|---|---|
| `default` | nixos | minimal | — | — | Шаблон |
| `atoridu` | atoridu | primary | — (manual) | 26.05 | xanmod, mini-PC, без nixos-hardware |
| `rydiwo` | rydiwo | secondary | deploy-rs | 26.05 | Chuwi MiniBook, NTFS `lamet-drive` (mask=0000) |
| `otrecа` | otreca | vds | deploy-rs | 25.05 | VPS, Tailscale-only SSH, nftables (нужен A3) |
| `sapphira` | sapphira | server | deploy-rs | 25.05 | Домашний сервер, `firewall.enable = false` намеренно |
| `wsl` | wsl | wsl | — (manual) | 24.11 | WSL на vetymae (Windows 192.168.1.100) |
| `epral` | epral | termux | — | 24.05 | Android nix-on-droid, через `mobile.nix` |

## Services (sapphira, активные)

20+ системных сервисов + 6 контейнеров. Полный инвентарь в `tasks/manifest.json` (задачи A1-F). Все, использующие `mkServiceStorage`, нуждаются в B1 guard: postgresql, samba, homebox, gitea, navidrome, syncthing, uptime-kuma, immich, nextcloud, calibre-web, 3x-ui, tape-rotation.

## Network

```
LAN 192.168.1.0/24:
  .20 sapphira  (зашит в ~30 мест; см. вопрос 6.6)
  .1  роутер (gateway)
  .100 vetymae (Windows-хост с WSL)

Tailscale CGNAT 100.64.0.0/10:
  100.64.0.0    = sapphira (назначен вручную, в 4 файлах)
  100.86.62.4   = opencode на vetymae
  100.106.21.39 = miniflux

Internet:
  sapphira: пробросы роутера = 22, 80, 443, 8443 (xray), 22000 (syncthing)
```

## Decisions in Effect

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-0001 | sops-пути: `config.sops.secrets.<name>.path` (не литерал) | active |

Подробнее: `.agent/decisions/0001-sops-secrets-paths.md`.

## Testing Status

Тестов нет. Единственная защита — `nix flake check`. Кандидаты на CI-проверки (7 штук) — в `analysis-report.md §5`.

## Open Concerns

- **B1**: нет guard'а на несмонтированный `/mnt/services` — сервисы стартуют на пустой БД.
- **A3**: nftables на VDS без явной финальной политики — неявный accept.
- **C1–C5**: 3x-ui заморожен, но без формального ADR; `podman.autoPrune` + `:latest` = деградация без коммита.
- **2.2/5.5**: `vetymae` / `lamet` / `therima` / `soptur` в `dirs.nix` — природа неясна.
- **4.1/4.2**: root-SSH и bootstrap-цикл ключа — не задокументированы.
- **6.6**: `192.168.1.20` зашит в 30 мест — рефакторинг отложен.

Полный список — в `roadmap/sources.md` (открытые вопросы слоёв 0-11).
