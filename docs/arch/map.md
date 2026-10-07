# Карта архитектуры

Полная карта репозитория: per-host детали, сетевая топология, инвентарь сервисов.
Слои 0–8 проработаны; слои 9–11 (home-manager, deploy, формат) см. в
`docs/arch/invariants.md`.

## Содержание

1. [Реестр хостов](#реестр-хостов)
2. [Идентичность и xlib](#идентичность-и-xlib)
3. [Диспетчеризация модулей](#диспетчеризация-модулей)
4. [Пользователь, SSH, секреты](#пользователь-ssh-секреты)
5. [Хранилище](#хранилище)
6. [Сеть и firewall](#сеть-и-firewall)
7. [Сервисы](#сервисы)
8. [Неотвеченные вопросы](#неотвеченные-вопросы)

---

## Реестр хостов

Единственная точка добавления/изменения хоста — `configurations/default.nix:13-39`.
Имя атрибута **равно** hostname; отдельное `hostname = …` только у `default`
(где attr = `default`).

| Attr | hostname | device.type | description |
|---|---|---|---|
| `default` | nixos | minimal | Шаблон, hostname `"nixos"`, `device = "minimal"` |
| `atoridu` | atoridu | primary | Основной десктоп, `xanmod` |
| `rydiwo` | rydiwo | secondary | Chuwi MiniBook, `xanmod`, NTFS-том `lamet-drive` |
| `otrecа` | otreca | vds | VPS, SSH только через Tailscale, `grub` без EFI |
| `sapphira` | sapphira | server | Домашний сервер, `firewall.enable = false` намеренно |
| `wsl` | wsl | wsl | WSL NixOS на Windows-хосте `vetymae` |
| `epral` | epral | termux | Android (`nix-on-droid`), отдельный путь конфигурации |

`device.type` ∈ { minimal, primary, secondary, server, vds, wsl, termux }.
Машина `vetymae` (Windows + WSL) фигурирует в `coredns`, `nginx`, `modules/server/systemd.nix`,
но **не** в реестре хостов — это внешний хост, через который заходят на WSL.

### Per-host summary

- **`atoridu`** (`primary/mini-pc`): без `nixos-hardware` (мини-ПК). Linux `xanmod_stable`,
  `systemd-boot`, EFI. `stateVersion 26.05`. → `configurations/mini-pc.nix`.
- **`rydiwo`** (`secondary/mini-laptop`): `nixos-hardware: chuwi-minibook-x`, xanmod,
  `systemd-boot`, EFI. **NTFS-том `xlib.dirs.lamet-drive`** с `mask = "0000"` —
  world-readable/writable по дизайну [?]. `stateVersion 26.05`.
- **`otrecа`** (`vds`): qemu-guest, GRUB без EFI, `disko` + `hardware/vds.nix`.
  `firewall.enable = true` + ручной `nftables.ruleset` без финального правила.
  `firewall.interfaces.tailscale0.allowedTCPPorts = [22]`. `stateVersion 25.05`.
- **`sapphira`** (`server`): systemd-boot, EFI, ext4 на UUID `37e53ebc-…-a8de`.
  bind-mount `/mnt/services` ← `/home/oqyude/External/Services`. `stateVersion 25.05`.
- **`wsl`**: `nixos-wsl` + NixOS-стек, IPv6 on, `firewall.enable = false`.
  `stateVersion 24.11`. Реальный Windows-хост — `vetymae`, `192.168.1.100`.
- **`epral`** (`mobile.nix`): не NixOS, **nix-on-droid**. `stateVersion 24.05`.

---

## Идентичность и xlib

`lib/xlib/` собирает чистые данные (без модулей):

```
xlib = {
  device = { hostname, type, username, uid, gid };
  isDesktop, isHeadless;     # ← от device.type через devices.<type>.{desktop,headless}
  dirs = mkDirs username;     # ← well-known пути, зависят только от username
  helpers = { mkBindMount, mkSystemdBind, mkServiceStorage, mkNtfsMount,
              mkExfatMount, mkTmpDirs, mkSymlinks };
}
```

- **`mkXlib`** (`lib/xlib/default.nix:38-77`) — единственная точка сборки; вызывается
  в `configurations/default.nix:50`. Прокидывается в каждый модуль как
  `xlib = …` через `lib/mkSystem.nix:specialArgs`.
- **`devices`** (`lib/xlib/device.nix:12-41`) — закрытое множество device.types.
  Неизвестный тип → throw со списком валидных. Добавление типа = новая папка
  `modules/<type>/` + `home/<type>.nix` + запись в `devices`.
- **`uid/gid`** зашиты как `?` `1000`/`1000` в `mkXlib`. Менять = инвентаризация
  во всех хостах, иначе расходятся владельцы файлов на NTFS/exFAT.
- **`sapphira`** — исключение: `users.nix:66` ставит `uid = 1001` для сохранения
  совместимости со старым `uid-map` (`yuyus` = 1000). `TODO: delete once
  sapphira migrated to 1000`. Цена: exFAT на sapphira получает `uid=1000` от
  `xlib.device.uid`, поэтому пользователь не может писать в `/mnt/archive` и
  `/mnt/mobile` до миграции.

---

## Диспетчеризация модулей

### `nixosModules.default` (`modules/default.nix:9-39`)

Импортирует на **каждый** NixOS-хост (включая `minimal`):

```
./essentials      → packages, services, settings, ssh, shell, systemd-routines
./options.nix     → host.builder.*, host."3x-ui".*
./users.nix       → пользователь, sops-секреты
home-manager.nixosModules.home-manager
sops-nix.nixosModules.sops
justray.nixosModules.default
disko.nixosModules.disko
grub2-themes.nixosModules.default
self.homeConfigurations.default.nixosModule
```

Плюс `lib.optional xlib.isDesktop ./desktop` (primary, secondary).
Плюс `lib.optional (!isDesktop && type != "minimal") (./. + "/${type}")`
(server, vds, wsl, termux). **termux** попадает сюда только в path nix-on-droid,
не как NixOS-хост (см. `mobile.nix`).

### `nixosModules.strict` (`modules/default.nix:40-53`)

Используется только `mobile.nix:22`. Импортирует `options.nix` +
`./<device.type>`; **всё** остальное NixOS-специфичное (essentials, users,
home-manager, sops, disko, grub2-themes) **выключено**, потому что nix-on-droid
не имеет `services.*`, `users.*`, `sops.*`, `disko.*` в своей модульной системе.

### Правило для кросс-модульных опций

Опция живёт в `modules/options.nix`, если её **устанавливает** один модуль,
а **читает** другой. `host.reader.X.enable` живёт в `essentials/ssh.nix`, потому
что его объявляет и использует один модуль.

---

## Пользователь, SSH, секреты

### Пользователь `oqyude`

- `uid` = `1000` на всех хостах, кроме `sapphira` (=`1001`, см. выше).
- `home = /home/oqyude`, `homeMode = "700"`.
- `linger = true` на всех хостах — user-services (opencode-web) переживают logout.
  Следствие: user-сервисы стартуют и потребляют ресурсы без активной сессии.
- `extraGroups`: `audio disk gamemode networkmanager pipewire wheel libvirtd qemu-libvirtd`.

### SSH

- `essentials/ssh.nix`: `services.openssh` включается через `host.ssh.enable`,
  `PermitRootLogin = "yes"` (намеренно для deploy), `PasswordAuthentication = false`,
  hostKey = `/etc/ssh/id_ed25519`.
- `authorizedKeys` для `oqyude` зашит в `users.nix:87` (`ssh-ed25519 AAAA…`).
  Чей — `[?]` (см. вопрос 4.1).
- `users.nix` определяет `root`-authorizedKeys **отсутствует** [?] — root как-то
  попадает на хост; deploy-rs использует `sshUser = "oqyude", user = "root"`.

### Циклическая зависимость ключа

`/etc/ssh/id_ed25519` одновременно:
- `hostKeys` для sshd (`essentials/ssh.nix:22`)
- `sops.age.sshKeyPaths` для расшифровки (`users.nix:95-97`)
- цель `ssh_key_private_known` (`users.nix:147-152`)
- цель `ssh_key_public_host` (`users.nix:159`)

Как разворачивается на чистой машине — **одноразовый bootstrap** [?].
Должен быть задокументирован, иначе при переустановке хоста агент не выведет.

### `.sops.yaml`

- Один age-ключ (`*default`), `path_regex: secrets/[^/]+\.(yaml|json|env|ini)$`.
- Покрывает только плоские файлы в `secrets/` (без подкаталогов).
- Добавление секрета = `secrets/<имя>.<yaml|json|env|ini>` строго в корне.
- Дополнительные секреты dotenv/json — через `mkUserSecret` (`users.nix:33-41`).

### Инвентарь секретов (`users.nix:100-162`)

| Секрет | Формат | Назначение |
|---|---|---|
| `hashed_password` | yaml | Пароль пользователя |
| `age_key_private` | yaml | `~/.config/sops/age/keys.txt` |
| `opencode_server` | dotenv | `~/.config/opencode/server.env` |
| `opencode_auth` | json | `~/.local/share/opencode/auth.json` (`key=""`) |
| `opencode_account` | json | `~/.local/share/opencode/account.json` (`key=""`) |
| `ssh_key_private` | yaml | `~/.ssh/id_ed25519` |
| `ssh_key_public` | yaml | `~/.ssh/id_ed25519.pub` |
| `ssh_key_private_root` | yaml | `/root/.ssh/id_ed25519` |
| `ssh_key_public_root` | yaml | `/root/.ssh/id_ed25519.pub` |
| `ssh_key_public_host` | yaml | `/etc/ssh/id_ed25519.pub` |

---

## Хранилище

### `/home/oqyude/External` (ext4)

- `sapphira`: UUID `37e53ebc-5343-a94d-9fe2-0ca39e13a8de`, fsType `ext4`,
  **без `nofail`**, **без automount** — обычный mount, без `x-systemd.automount`,
  не помечен как `requiredBy local-fs.target` явно, но NixOS добавляет это для
  всех `fileSystems` без `nofail` [?].
- `rydiwo`: не смонтирован (у ноутбука есть только NTFS `lamet-drive`).
- На других NixOS-хостах — не заявлен (нет внешнего диска).

### `/mnt/services` (bind)

- `server.nix:49-52`: `mkBindMount` от `xlib.dirs.services-folder`
  (= `/home/oqyude/External/Services`) к `/mnt/services`, `bind,nofail`.
- `server.nix:61-63`: tmpfiles `z /mnt/services 0777 root root`.
- `vds/default.nix:23`: tmpfiles создаёт `/mnt/services` с правами `0755`.
- Используется сервисами на sapphira для bind-mount сервисных данных
  (`mkServiceStorage`) и как прямой `stateDir` для gitea/memos/calibre-web/
  immich/nextcloud/step-ca/trilium/uptime-kuma/3x-ui/tape-rotation.

### `/mnt/archive`, `/mnt/mobile`, `/mnt/lamet`, `/mnt/therima`, `/mnt/vetymae`, `/mnt/soptur`

- `archive` и `mobile` смонтированы на sapphira через `mkExfatMount`
  (`nofail`+uid=1000).
- `lamet` — NTFS на rydiwo (`mask = "0000"`).
- `therima`, `vetymae`, `soptur` — **не** смонтированы нигде в репозитории
  (см. вопрос 2.2).
- `dirs.nix` объявляет их все; `dirs.nix` **не** читать как список дисков этой
  системы — там имена, часть из которых не существует.

### Потребители External-диска и порядок защиты

Включённые на sapphira сервисы с данными на `/mnt/services` или `/home/oqyude/External`:

- `postgresql`, `samba-smbd`, `homebox` (+setup), `gitea` (+dump),
  `navidrome`, `syncthing`, `uptime-kuma`, `immich-server` (+ML),
  `nextcloud`, `calibre-web`, `podman-3xui_app`, `podman-tape-rotation`

Все они обязаны иметь guard на `requiresMountsFor` (задача **B1** в `todo.md`).
Сейчас guard есть **только** у rsync-юнитов (`modules/server/systemd.nix:14,36`),
которые используют `--delete` и потенциально самые опасные при отсутствующем
диске.

---

## Сеть и firewall

### Топология

```
Интернет (роутер, белый IP)
    ├── router NAT/proxy → sapphira:  443, 80, 22000, 8443, 22  (5 портов)
    │
    └── otreca (VPS): SSH только через Tailscale, не пробрасываем

LAN (192.168.1.0/24)
    ├── 192.168.1.20   = sapphira (домашний сервер)
    ├── 192.168.1.1    = роутер (gateway)
    ├── 192.168.1.100  = vetymae (Windows-хост; на нём — WSL NixOS = `wsl`)
    ├── 192.168.1.101, .102  = соседние машины (rsync/таблица в `termux.nix`)
    └── ...

Tailscale (CGNAT 100.64.0.0/10)
    ├── 100.64.0.0     = sapphira (назначен вручную)
    ├── 100.64.1.0     = ещё один узел [?]
    ├── 100.86.62.4    = opencode на vetymae
    └── 100.106.21.39  = miniflux на другом узле
```

`192.168.1.20` зашит в ~30 местах: `modules/server/{nginx,coredns,nfs,open-webui}.nix`,
`configurations/*`. `100.64.0.0` — в `nginx.nix`, `nextcloud.nix`,
`modules/vds/{nginx,systemd}.nix`.

### DNS (`modules/server/coredns.nix`)

Зоны `zeroq.su` (~17 записей) и `home.arpa` (~17) определены вручную.
Дублируют инвентарь сервисов: добавление сервиса = правка `coredns.nix` +
`nginx.nix` + самого модуля.

### Firewall

| Хост | `firewall.enable` | Фильтрация |
|---|---|---|
| sapphira | **false** (намеренно) | Роутер пробрасывает 5 портов: **443, 80, 22000, 8443, 22** |
| otreca | true | Самописанный nftables **без финального правила** → неявный accept; `firewall.interfaces.tailscale0.allowedTCPPorts = [22]` |
| wsl | false | WSL — не сетевой периметр |
| rydiwo, atoridu | default | `desktop` правила |

Следствия:
- На `sapphira` `openFirewall`/`allowedTCPPorts` не имеют эффекта.
- `nginx.nix:225` (`allowedTCPPorts = [80 443]`) — **мёртвое** правило.
- Допустимо `0.0.0.0` на любом сервисе sapphira — он не открывается в интернет
  без проброса на роутере.
- На `otrecа` ruleset требует финальной политики (задача A3).

### SSH

`otreca` достижима только через Tailscale: `services.openssh.openFirewall = false`,
`firewall.interfaces.tailscale0.allowedTCPPorts = [22]`. Но при `nftables.enable`
с ручным ruleset это правило может не дойти до файрвола — проверить
`nft list ruleset` на otreca до правок (задача A3).

---

## Сервисы

### Системные (sapphira, в `modules/server/default.nix:imports`)

Сервисы в `imports` + `state` + `roles`:

| Сервис | Файл | Порт | Данные | Guard? |
|---|---|---|---|---|
| acme (Let's Encrypt) | `modules/server/acme.nix` | — | `/var/lib/acme` | — |
| bentopdf | `bentopdf.nix` | — | — | — |
| builder (remote) | `builder.nix` | — | — | — (опция выключена) |
| calibre-web | `calibre-web.nix` | 8083 | `services-mnt-folder/calibre-web(-library)` | нужен B1 |
| chrony | `chrony.nix` | — | — | — |
| coredns | `coredns.nix` | 53 | inline zone | — |
| gitea | `gitea.nix` | 3000 | `services-mnt-folder/gitea` | нужен B1 |
| glances | `glances.nix` | — | — | — |
| homebox | `homebox.nix` | 7745 | `mkServiceStorage` | нужен B1 |
| immich | `immich.nix` | 2283 | `services-mnt-folder/immich` | нужен B1 |
| miniflux | `miniflux.nix` | 6061 | — | — |
| navidrome | `navidrome.nix` | 4533 | `server-home/Music` | нужен B1 |
| nextcloud | `nextcloud.nix` | 10000 | `services-mnt-folder/nextcloud` | нужен B1 |
| nginx | `nginx.nix` | 80/443 | proxy-only | — |
| nix-serve | `nix-serve.nix` | 5000 | — | — |
| onlyoffice | `onlyoffice.nix` | (через nginx) | — | — |
| postgresql | `postgresql.nix` | (local) | `mkServiceStorage` | нужен B1 |
| power | `power.nix` | — | — | — |
| samba | `samba.nix` | ? | `mkServiceStorage` | нужен B1 |
| syncthing | `syncthing.nix` | 8384 (gui), 22000 (data) | `server-home`, `storage/persist/...` | нужен B1 |
| systemd (rsync oneshots) | `systemd.nix` | — | источник/приёмник — оба на External | **уже есть guard** |
| uptime-kuma | `uptime-kuma.nix` | 4001 | `services-mnt-folder/uptime-kuma` | нужен B1 |

Закомментированы в `imports` (всё ещё живой код, потенциальный шум):
`remnawave, coturn, mealie, memos, minecraft, n8n, netdata, nfs, open-webui,
rsync, step-ca, stirling-pdf, transmission, trilium, zerotier` — см. задачу **E3**.

### Контейнеры (`modules/containers/`)

| Контейнер | Файл | Данные | Примечание |
|---|---|---|---|
| 3x-ui | `3x-ui.nix` | `services-nodes-folder/<host>/3x-ui/{db,cert}` | **Заморожен**, см. ниже |
| tape-rotation | `tape-rotation.nix` | `services-nodes-folder/<host>/tape-rotation` | — |
| remnawave | `remnawave.nix` | `/mnt/services/containers/remnawave` | **закомментирован** в `server/default.nix` |
| remnanode | `remnanode.nix` | `/mnt/services/containers/remnanode` | — |
| kokoro-tts | `kokoro-tts.nix` | — | — |
| openhands | `openhands.nix` | — | — |
| remnawave-examples | `remnawave-examples/*.nix` | docker-compose | шаблоны |

### 3x-ui — замороженное состояние

Образ: `ghcr.io/mhsanaei/3x-ui:latest` (**не запинен**). Ядро Xray — на 26.7.x,
миграция на 26.9.x провалена. Панель может обновиться из upstream — поэтому:
- `podman-update-3xui_app` (`3x-ui.nix:80-90`) с `podman pull …:latest`
  + `systemctl restart` — **таймер закомментирован**.
- `podman.autoPrune.flags = ["--all"]` (`3x-ui.nix:45-47`) — потенциальный риск:
  авто-prune может смести панель без коммита в репозиторий.

`reality443Forwarding = true` (`modules/vds/default.nix:19`) — следствие отката
`c8d4a12`; смысл утрачен, см. задачу **C5**.

### Nginx (`modules/server/nginx.nix`)

~12 vhost'ов через `mkProxy` для обратного проксирования сервисов на 192.168.1.20.
Плюс несколько hand-written:

- `nextcloud.private` — слушает на `100.64.0.0:10000` (= Tailscale sapphira),
  `192.168.1.20:10000`, `127.0.0.1:10000`.
- `office.zeroq.su` — проксирует на nextcloud onlyoffice.
- `pdf.private` — слушает `0.0.0.0:80`, `100.64.0.0:8446`, `192.168.1.20:8446`,
  `127.0.0.1:8446` (для Nextcloud PDF).
- `x.zeroq.su` — 3x-ui controller panel + `/subs/`, `/subsjs/`, `/clash/`.
- `zeroq.su` — корневой, заглушка + `/guest/` → LAN `:80`.
- `vetymae.opencodes.zeroq.su` → `100.86.62.4:4096`.
- `lamet.opencodes.zeroq.su` → `100.106.21.39:6061` — **порт miniflux**; либо
  ошибка, либо так задумано [?] (см. вопрос 8.2).
- `opencode.zeroq.su` → `127.0.0.1:4096` (opencode-web на самом sapпира).
- `nextcloud.zeroq.su` → `192.168.1.20:10000`, `/whiteboard` → `:3002`.

`networking.firewall.allowedTCPPorts = [80 443]` (строка 225) — **мёртвое** правило
при `firewall.enable = false`.

---

## Неотвеченные вопросы

Слои 9–11 (home-manager, deploy, формат) оставлены для прочтения в
`docs/arch/invariants.md`. Неотвеченные вопросы слоёв 1–8:

| ID | Вопрос |
|---|---|
| 2.2 | `vetymae` / `lamet` / `therima` / `soptur` — те же машины или хосты вне репозитория? |
| 2.5 | `stateVersion` дрейфует 24.05 / 24.11 / 25.05 / 26.05 — намеренно? |
| 2.6 | Есть ли escape hatch для per-host отличий в `xlib`? |
| 3.2 | `any.nix` (minimal) действительно нуждается в home-manager + sops + disko? |
| 4.1 | Как root получает доступ по SSH — `authorizedKeys` для root в коде нет |
| 4.2 | Как разрешается цикл «ключ в секрете, а нужен для расшифровки»? |
| 4.3 | Все файлы в `secrets/` покрыты `path_regex`? |
| 4.4 | Как подключается вторая машина / второй человек при одном age-ключе? |
| 4.5 | `users.nix:87` — личный ключ или общий «ключ от деплоя»? |
| 5.1 | `/mnt/services` в режиме 0777 — осознанно? |
| 5.3 | NFS выключен, Samba работает — миграция? |
| 5.4 | NTFS-том `lamet-drive` с `mask = "0000"` — что на нём лежит? |
| 5.5 | `therima` / `vetymae` / `soptur` — несуществующие остатки или сетевые шары? |
| 5.6 | Где бэкапы БД и 3x-ui? |
| 6.6 | `192.168.1.20` зашит в 30 мест — считаем константой? |
| 6.7 | DNS дублирует инвентарь сервисов — как проверяем рассинхрон? |
| 6.8 | Публичные IP и SSH-алиасы в `home/termux.nix` — карта «хост → адреса» нужна? |
| 6.9 | Какой путь REALITY считается правильным? (→ C5) |
| 7.4 | Почему не публиковать весь диапазон 14380-15379? |
| 8.2 | `lamet.opencodes` → `:6061` — ошибка или так задумано? |
| 8.4 | `onlyoffice` — работает после трёх регрессов? |
| 8.5 | Что слушает `:3002` (`/whiteboard` в nextcloud)? |