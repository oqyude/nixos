# nixos — домашний флот на NixOS

Конфигурация шести NixOS-хостов и одного Android-устройства. Один флейк,
один реестр адресов, одна машина проверок.

| Attr | Хост | Роль | device.type | Деплой | stateVersion |
|---|---|---|---|---|---|
| `atoridu` | mini-PC | основной десктоп | primary | вручную | 26.05 |
| `rydiwo` | Chuwi MiniBook | второй десктоп | secondary | deploy-rs | 26.05 |
| `sapphira` | домашний сервер | сервисы, nginx, DNS | server | deploy-rs | 25.05 |
| `otrecа` | VPS | 3x-ui, Xray REALITY | vds | deploy-rs | 25.05 |
| `wsl` | WSL на vetymae | сборка, эксперименты | wsl | вручную | 24.11 |
| `epral` | Android | nix-on-droid | termux | вручную | 24.05 |
| `default` | — | минимальный шаблон | minimal | — | — |

Адреса, DNS, сети и общие порты лежат в **`lib/xlib/net.nix`** — единственном
месте, где им положено жить. Модули читают их как `xlib.net.hosts.<host>.<if>`.

## Структура

```
flake.nix                 флейк: inputs, outputs (конфигурации, пакеты, devshell'ы)
configurations/           реестр хостов (1 запись = 1 машина) + тело модулей
  default.nix             сам реестр: аттрибут = hostname
  hardware/ disko/        железо и разметка по хостам
modules/                  NixOS-модули (essentials, server, vds, desktop, ...)
  options.nix             кросс-модульные опции
home/                     home-manager (по device-type)
lib/xlib/                 чистые данные: device, dirs, net (реестр), helpers
deploy/                   deploy-rs
.ci/                      проверки: checks.sh, tests/, verify/
.agent/                   состояние MetaAgent: ADR, правила, задачи, решения
AGENTS.md                 то, что агент читает ДО первого изменения
```

## Проверки

```bash
# всё, что CI делает на сапфире (быстро, без сборки)
bash .ci/checks.sh --no-build

# только сапфира (как в CI)
nix build .#nixosConfigurations.sapphira.config.system.build.toplevel

# все хосты (медленно: 7 конфигураций) — вручную, через workflow
# «evaluate all hosts» на Gitea

# форматирование
nix develop .#fmt --command treefmt

# гейт «ничего не должно поменяться» (как в CI)
nix develop .#fmt --command treefmt --fail-on-change .
```

Проверки, которые закрывают реальные классы поломок, а не стиль:

| # | Что ловит | Где |
|---|---|---|
| #1 | контейнер с `:latest` без пинa | `.ci/checks.sh` |
| #7 | sops-файл вне `path_regex` | `.ci/checks.sh` |
| #8 | импорт на несуществующий файл | `.ci/tests/import-graph.py` |
| #9 | `.agent`-метаданные против своих схем | `.ci/tests/validate-metadata.py` |
| #10 | DNS-запись без vhost (и наоборот) | `.ci/tests/check-domains.py` |
| #11 | `listen.addr` — сеть вместо интерфейса | `.ci/tests/check-listen-addrs.py` |
| #12 | расхождение статусов задач в `.agent` | `.ci/tests/check-agent-consistency.py` |
| #13 | shell-скрипт с предупреждениями ShellCheck | `.ci/checks.sh` |

Проверки #8–#12 — обычные python-скрипты без зависимостей; они запускаются
из `.ci/checks.sh`, а тот — и в CI, и в pre-commit хуке. #13 (ShellCheck)
пропускается, если `shellcheck` нет в PATH — он есть в devshell `.#fmt`.

> **Почему нет `formatter` во флейке и почему проверки не в `checks.*`.**
> `formatter` невозможен из-за бага nix 2.34.9: при проверке этого вывода nix
> перебирает **имена атрибутов** derivation'а и трактует каждый как системный
> тип — `"'outPath' is not a valid system type"`. Воспроизводится даже на
> флейке без инпутов, с hand-written derivation'ом, — nixpkgs тут ни при чём.
> Поэтому форматтер живёт в devshell `nix develop .#fmt`
> (treefmt + nixfmt + shfmt).
>
> Вывод `checks` при этом работает (checks deploy-rs уже есть во флейке и
> проходят), но python-проверки оставлены в `.ci/checks.sh` по двум
> причинам: derivation видит только закоммиченный flake source, а не рабочее
> дерево, которое нужно pre-commit'у; и имя `checks` уже занято проверками
> deploy-rs. Подробности — ADR-0011.

## Доказательство «функционал не изменился»

```bash
# снимок поведения всех хостов
.ci/verify/config-fingerprint.sh /tmp/before
# ... правка ...
.ci/verify/config-fingerprint.sh /tmp/after
diff -r /tmp/before /tmp/after && echo "поведение не изменилось"
```

Снимок берёт только те части конфигурации, которые что-то значат
(юниты, порты, vhost'ы, зона DNS, пакеты, монтирования, контейнеры) и не
содержит значений секретов.

**Обе ревизии материализуй одинаково.** Store path — часть снимка, а он
зависит от исполняемого бита файла, из которого сделан. Копия с Windows
(`/mnt/c`) считает всё исполняемым, `git archive` восстанавливает режим из
git-индекса. Сравнишь рабочую копию с архивом — получишь «разницу» в
`overlays/patch-whitesur-sddm.pl`, а за ней потянется `system-path`,
`XDG_DATA_DIRS` в `accounts-daemon.service` и `X-Restart-Triggers` у
`dbus-broker` и `polkit`. Байты те же — обёртка другая:

```bash
git archive dev   | tar -x -C /tmp/dev
git archive agent | tar -x -C /tmp/agent
(cd /tmp/dev   && .ci/verify/config-fingerprint.sh /tmp/fp-dev)
(cd /tmp/agent && .ci/verify/config-fingerprint.sh /tmp/fp-agent)
diff -r /tmp/fp-dev /tmp/fp-agent
```

Отдельно — сверка декларации с работающим хостом (`podman inspect`,
`systemctl show`, `nginx -T`):

```bash
bash .ci/verify/runtime-drift.sh          # на самом хосте, от root
```

Это закрывает класс «в nix всё правильно, в проде — нет»: порты контейнера
применяются только при пересоздании, а `nginx -T` показывает, что реально
загружено.

## Деплой

```bash
# сапфира (deploy-rs)
nix run .#deploy -- --hosts sapphira

# что изменится на хосте
nixos-rebuild dry-build --flake .#sapphira
```

Хост `rydiwo` — ноутбук, он может быть выключен: `let deploy` с живыми
нодами проверяйте перед раскаткой.

## Ловушки

Репозиторий полон мест, где «так выглядит сломанным, но это не баг»
(дефолтный `firewall.enable = false` на сапфире, закомментированные модули,
`stateVersion` ниже текущей). Полный список — в `AGENTS.md`, раздел
«Ловушки», и в `.agent/rules/project-rules.md` (правила R1 с обоснованием).
Там же — 18 подтверждённых инвариантов: их нарушение ломает прод тихо.

## Метаданные агента

`.agent/` — состояние MetaAgent: ADR (архитектурные решения), правила,
реестр задач, контекст проекта. Машиночитаемый источник истины по задачам —
`.agent/tasks/manifest.json`; `AGENTS.md` содержит сводку, и её согласованность
с манифестом проверяется check #12.
