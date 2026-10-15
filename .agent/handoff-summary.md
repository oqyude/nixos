# Handoff Summary

## Session Summary

**Session:** metaagent-init-2026-10-09 (продолжение 2026-10-15T03:00)
**Goal:** проход METASTATE (протокол 06, шаги 6.4 / 6.5 / 6.7) — привести
повествовательный слой `.agent/` в соответствие с кодом и с книгой задач.
**Completed:** 14 задач (T1, T2, T5–T9, T11–T17)
**Pending:** 4 задачи (T3, T4, T10, T18)
**Approved requests:** нет — каталога `.agent/requests/` не существует,
нечего ревьюить
**Host:** sapphira (`nixos-rebuild switch --flake .#sapphira`)

---

## ⚠️ Начните отсюда: есть незакоммиченная работа

`modules/server/gitea-runner.nix` — **изменён, применён к хосту, но не закоммичен**.
Это единственное, что потеряется при пересборке из чистого клона.
Задача заведена как **T18**.

```bash
git status --short                      # M modules/server/gitea-runner.nix
git diff -- modules/server/gitea-runner.nix
```

Ветка `dev`, remote `gitea`.

---

## Completed

### Закрыто и запушено (`gitea/dev`)

| Коммит | Что |
|---|---|
| `3babee5` | Удалён плагин `@bybrawe/opencode-loop` из `home/modules/opencode.nix` (обе точки: `settings.plugin` → `opencode.json`, `tui.plugin` → `tui.json`) |
| `d021804` | `secrets/gitea-runner-registration.env`: placeholder → настоящий токен Gitea (40 симв.). Проверено через `sops -d` сравнением хешей; в коммит попал только шифротекст |

Ранее в этом же дне: `0df9688` (ревью T17 + T10 + T15 + T15/any.nix/wsl),
`61b3724` (Wave 1: T4-часть, T7, T3-часть, T5, T15, T16, T6),
`07a0437` (возврат `reality443Forwarding` — R1.10).

### Сделано, не закоммичено (T18)

1. **Устранён фантомный юнит.** `systemd.services.gitea-runner-ci-sapphira` (обычный дефис) заменён на `systemd.services.${unitKey}`, где `unitKey = "gitea-runner-ci\\x2dsapphira"` — байт-в-байт как в upstream `nameValuePair "gitea-runner-${escapeSystemdPath name}"`. Юнит не имел `ExecStart` и systemd отказывался его запускать с **2026-10-14 16:25** по **2026-10-15 01:23**.
2. **`assertions`-растяжка** — `nix build` упадёт, если ключ снова разъедется с upstream. Три предыдущие попытки чинили баг молча.
3. **Дисковый гвард заменён реальной зависимостью.** `Wants`/`After` на `nginx.service` + `gitea.service`. Гвард охранял пустое множество: у живого раннера **ноль** дескрипторов на внешнем диске (cwd на корне, workdir в `/tmp`, токен на корне).
4. **`serviceConfig.RestartSec = lib.mkForce "30s"`** — upstream даёт `RestartSec=2`, что крутит журнал при задержке TLS. `Restart=on-failure` уже был от upstream, его не трогаем.

### Закрыто документацией (этот проход)

- **R1.14** внесён в `rules/project-rules.md` (задача T19): имя атрибута
  `systemd.services.<…>` должно байт-в-байт совпадать с тем, что отдал
  upstream `nameValuePair`, иначе фантомный юнит без `ExecStart`.
- **ADR-0002** переведён из `draft` в `accepted`: бэкапы объявлены вне Nix,
  вопрос 5.6 владельцем так и не отвечен, риск принят формально (R1.9).
- **Синхронизированы фазы** в `checkpoints.json` и `tasks/manifest.json`
  (`analyse` / `roadmap` / `decomposition` / `metastate` расходились:
  в одном файле `pending`, в другом `completed`).
- **Удалён дубликат** `.agent/tasks/manifest.md`. Источник истины по задачам —
  один: `tasks/manifest.json`.

---

## Pending

| ID | Задача | Статус |
|---|---|---|
| **T18** | Закоммитить и запушить фикс gitea-runner | **pending** ← следующий шаг |
| **T4** | Guard на `/mnt/services` | pending, **severity: high** |
| T3 | Финальная политика nftables на VDS | pending |
| T10 | Судьба `reality443Forwarding` | pending |

Все T1–T17, кроме T3/T4/T10, — `completed`. Ни одна из четырёх открытых
задач в этом проходе не закрывалась: закрытие задач — не работа метасостояния.

### T4: мёртвый гвард, severity high

`mkStorageGuard` (`lib/xlib/helpers.nix:180-189`) возвращает ровно одно поле —
`ConditionPathIsMountPoint = [ xlib.dirs.server-home ]`, а это директива
секции **`[Unit]`**. Все потребители передают её через `serviceConfig`, и она
рендерится в `[Service]`, который systemd **не читает**. Подтверждено
построчным чтением отрендеренных юнитов на sapphira 2026-10-15: у `gitea`
секция `[Service]` начинается со строки 5, а `ConditionPathIsMountPoint`
лежит на строке 14. Перепроверено на текущем юните: `[Unit]` = 1,
`[Service]` = 5, условие = 14, `[Install]` = 61. Надёжный признак мёртвого
гварда — сама директива в `[Service]`, а не номера строк: они меняются при
каждом перерендеривании.

Мёртв на **13 юнитах / 12 сервисах**: `postgresql`, `samba`, `homebox`,
`gitea`, `navidrome`, `syncthing`, `uptime-kuma`, `immich`, `nextcloud`,
`calibre-web`, 3x-ui (`podman-3xui_app`), tape-rotation (два юнита:
`podman-taperotation-backend` и `podman-taperotation-frontend`).

`RequiresMountsFor` в хелпере **нет намеренно**: такая зависимость заставит
systemd сам монтировать ФС при старте юнита, и гвард обессмыслится (проверено
на sapphira 2026-10-10). Порядок должен задаваться через `After=` на
`.mount`-юнит в самом потребителе.

Гвард с `gitea-runner` убран осознанно — он охранял пустое множество. Цена
решения: гвард Gitea (данные в `/mnt/services/gitea`) по-прежнему мёртв, значит
Gitea может стартовать на пустой БД, а раннер поднимется и пойдёт гонять job'ы
по ней. **Риск снимается только закрытием T4.**

### T3: nftables на otreca

Ruleset живёт в `configurations/vds.nix:71-91` (цепочка `input`), `policy` не
объявлен, последнего правила нет → неявный accept. К `modules/vds/systemd.nix`
это отношения не имеет. Правки T3 уже откатывались один раз по требованию
владельца, обсуждение не завершено.

---

## Три ошибки подряд — баг пережил три неверных диагноза

Каждый следующий диагноз не проверял предыдущий, а закреплял его. Общая
форма: теория, повёрстая в документ, перестаёт проверяться.

1. **`systemctl show <юнит>` по неверному имени возвращает дефолты, а не ошибку.** Имя на диске содержит литеральный `\x2d`, поэтому `systemctl show gitea-runner-ci-sapphira` молча отдаёт `Restart=no`, хотя в файле `Restart=on-failure`. **Диагностировать юнит — читать файл**, не `systemctl show`.
2. **Зелёная сборка ≠ рабочая конфигурация.** `wants`/`after`, положенные в `unitConfig`, молча не рендерились: сборка прошла, а в юните остались только `network-online.target` от upstream. Они работают только как **первоклассные опции верхнего уровня**, слитые через `lib.mkAfter`.
3. **Вывод `e6e82b8` («`serviceConfig` нельзя мержить») ложный — и это НЕ про гвард.** С правильным ключом `serviceConfig` мержится штатно. Дефект гварда другой: **секция** (`ConditionPathIsMountPoint` — директива `[Unit]`, отрендеренная в `[Service]`). Два разных отказа; их смешение и породило противоречивые заметки в `checkpoints.json`. На ложном выводе были отложены cgroup caps «на drop-in».

Проверка на фантом (обе формы в `attrNames`):

```bash
nix eval --raw .#nixosConfigurations.sapphira.config.systemd.services \
  --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' \
  | grep -i gitea-runner
```

---

## Ещё два хвоста (не задачи, но висит)

1. **Плагин opencode-loop ещё жив в текущем процессе.** `opencode-web` = PID 1645, конфиг читается один раз при старте. Плагин исчезнет после `systemctl --user restart opencode-web`. Не делал: это оборвало бы сессию.
2. **CI на Gitea не проверен.** Юнит `active/running`, `ExecStart` на месте, но приём job'ов сервером не подтверждён. Проверяется пушем в `dev` — тем же пушем, что закрывает T18.

---

## Что изменил этот проход METASTATE

Документация сверялась не «по памяти», а против кода и против
`tasks/manifest.json`. Расхождения, которые были исправлены:

| Что | Было в доках | Стало |
|---|---|---|
| Контейнеры на sapphira | 6 | **4**: `3xui_app`, `taperotation-backend`, `taperotation-frontend`, `open-webui` |
| Имя хелпера | `mkServiceStorage` | **`mkStorageGuard`** (`lib/xlib/helpers.nix:180-189`) |
| Охват мёртвого гварда | 10 сервисов | **13 юнитов / 12 сервисов** |
| R1.2 | утверждала отсутствие `RequiresMountsFor` как упущение | отсутствие **намеренное**, с обоснованием и датой проверки |
| Ловушка `serviceConfig` в opencode | ссылка на `home/modules/opencode.nix:339` | баг **уже починен в `c73a698`**, рабочая точка — `home/modules/opencode.nix:407`; 339-350 устарели |
| `modules/server/default.nix:37-50` | «14 закомментированных модулей» | закомментированных импортов **ноль**; строки 38-43 — комментарий, документирующий архив |
| `checkpoints.json` ↔ `manifest.json` | задокументировано как «синхронизировано» | расходились по фазам, **синхронизировано сейчас** |
| `tasks/manifest.md` | «устарел» | **удалён** 2026-10-15 |
| ADR-0002 | `draft` | **accepted** (R1.9, принятый риск) |
| `roadmap/sources.md` | «CI нет» | CI есть (`.ci/checks.sh`, `.pre-commit-config.yaml`, `.github/workflows/nix-checks.yml`), 3 проверки из 7 |
| ADR-0002 / R1.14 | не были в таблицах инвариантов | добавлены строки |

Правило, которое из этого следует: **инвариант, не подтверждённый чтением
кода в этой сессии, не переносится в следующий документ как истина.**
Числа в `project-state.md` придётся перепроверять, а не принимать на веру.

---

## Project State

- **7 outputs:** 6 NixOS (`atoridu`, `rydiwo`, `otrecа`, `sapphira`, `wsl`,
  `default`-шаблон) + `nixOnDroidConfigurations.epral`. `nix flake check`
  проходит, включая все 6 хостов и epral (T2).
- **4 активных контейнера** на sapphira; `remnanode.nix` — tmpfiles,
  `remnawave-examples/` не импортируется.
- **Сетевая граница sapphira — роутер**, 5 портов (R1.3). `firewall.enable = false`
  намеренно, пробросы нигде не выражены в Nix.
- **3x-ui заморожен**: панель на `:latest`, ядро Xray 26.7.x, TLS терминирует
  панель, не nginx (R1.10–R1.13). Правки нет.
- **`100.64.0.0`** = Tailscale-адрес sapphira, 4 файла / 5 строк (R1.4).
- Подробности: `.agent/context/project-state.md`.

---

## Next Steps

1. **Закоммитить и запушить `modules/server/gitea-runner.nix`** в `dev`
   (T18). Перед коммитом убедиться, что `gitea-runner-ci\\x2dsapphira` —
   единственный ключ в `systemd.services`.
2. **Пуш в `dev`** — заодно проверяет приём job'ов Gitea Actions (хвост №2).
3. **T4** — единственный открытый вопрос severity: high. Перенести условие в
   first-class опцию юнита, `RequiresMountsFor` не добавлять.
4. **T3 и T10** — требуют решения владельца, не трогать без обсуждения:
   оба уже откатывались один раз.

---

## Key Artifacts

- Состояние: `.agent/context/project-state.md`
- Задачи: `.agent/tasks/manifest.json` (единственный источник истины)
- Roadmap: `.agent/roadmap/sources.md`
- Правила: `.agent/rules/project-rules.md` (R1.1–R1.14, R2)
- Решения: `.agent/decisions/index.json`, `0001`, `0002` (accepted), `0003`, `0004`
- Код: `modules/server/gitea-runner.nix` — **не закоммичен**
- Архив модулей: `archive/server-modules/` (12), `archive/containers/` (3)