# ADR-0008: PowerShell в системные пакеты sapphira — ps1-реализация директора становится исполняемой на хосте

**Статус:** accepted, **не развёрнут** (правка в ветке `agent/powershell-env`;
активация = `nixos-rebuild switch --flake .#sapphira` владельцем/директором).

**Дата:** 2026-10-27

**Контекст.**

На sapphira живёт `metaagent-director` — оркестратор, у которого **две
реализации одной контрактной поверхности**: `director.sh` (+ `lib/*.sh`) и
`director.ps1`, плюс общий набор python-программ `python/*.py`, которые
вызывают обе. Контракт директора (`AGENTS.md` в том репозитории) прямо
фиксирует, что ps1-ветка проверяется **только чтением**: на хосте нет
`pwsh`, поэтому её тесты уходят в skip, и расхождения sh/ps1 (известный
класс дефектов — четыре штуки, найденные в T30: хардкод `S:/Git/...`,
`replace("`n", ' ')`, lowercase пути, свой regex `VERDICT:`) ловятся глазами,
а не прогоном.

`powershell` в этом репозитории уже присутствует, но **не в системном PATH**:

- `lib/ci-tools.nix:31` — список инструментов, из которого
  `modules/server/gitea-runner.nix` строит PATH **host-mode джоб** и
  `devshells/default.nix` — devshell `ci`. Это PATH джобы, а не хоста:
  интерактивная сессия, воркер директора и `pwsh ./tests/....ps1` из
  домашнего каталога его не видят.

То есть вопрос не «есть ли PowerShell в репозитории», а «должен ли он быть в
системном окружении хоста». Владелец 2026-10-27: «добавь на текущий хост
(sapphira) powershell в системное окружение, после чего появится возможность
прогонять ps1-тесты здесь».

**Решение.**

`configurations/server.nix` — `environment.systemPackages = [ pkgs.powershell ];`.

Место выбрано по границе «хост, а не пользователь» и «один хост, а не флот»:

- `configurations/server.nix` — тело модуля **ровно одной** записи реестра
  (`sapphira`, см. `configurations/default.nix:31-34`). Правка здесь
  физически не может изменить другой хост: у остальных записей свои файлы
  (`mini-pc.nix`, `mini-laptop.nix`, `vds.nix`, `wsl.nix`, `any.nix`).
- `modules/essentials/packages.nix` — общий список **всех** NixOS-хостов
  флейка, включая 1-vCPU vds `otreca`. Это неверная граница: `.NET`-рантайм
  нужен на одном сервере, где гоняются ps1-тесты, а не на VDS и не на
  ноутбуках.
- `modules/server/*` — каталог модулей **сервисов** (gitea, nginx, authelia,
  …), каждый со своими `host.<feature>` опциями и, при необходимости, своим
  `environment.systemPackages` (пример — `modules/server/authelia.nix:82`).
  PowerShell не сервис и не фича с опцией: это инструмент хоста, поэтому
  отдельный модуль завёл бы опцию ради одной строки.
- `pkgs.powershell` — nixpkgs-атрибут 7.x (на текущем пине `7.6.6`,
  замыкание **300.2 MiB**), не `powershell_7_2`-алиасы и не `dotnet`-сборка
  руками.

**Обоснование.**

- **Проверяемость вместо чтения.** ps1-ветка директора перестаёт быть
  «код, который никто не запускал»: её тесты исполняются на том же хосте,
  где живёт sh-ветка, с теми же путями и тем же окружением.
- **Одна строка, откат — одна строка.** Ни опций, ни новых модулей, ни
  оверлеев; `git revert` возвращает состояние ровно как было.
- **Цена локализована.** +300 MiB замыкания только на sapphira; у хостов с
  5.6 GiB RAM и внешним диском это не тот класс траты, который требует
  отдельного решения, а на VDS он был бы неоправдан.

**Альтернативы и почему не выбраны.**

1. **`modules/essentials/packages.nix`.** Отклонено: тянет `.NET` на все
   хосты, включая `otreca` (1 vCPU, диск VDS) и WSL, где ps1-тестов нет.
2. **Новый `modules/server/tools.nix`.** Отклонено: каталог `modules/server/`
   держит сервисы; «модуль инструментов хоста» из одной строки — структура
   без содержания. Если таких инструментов станет несколько, вынос в
   отдельный модуль — отдельное решение, а не побочный эффект этого.
3. **Только devshell/`ci-tools.nix` (как сейчас).** Отклонено: это PATH
   джобы/шелла. Интерактивная сессия и воркер директора в неё не входят, а
   именно они и прогоняют ps1-тесты.
4. **`nix shell nixpkgs#powershell` на каждый запуск.** Отклонено: реестр
   nix на sapphira пуст (тот же аргумент, что в `lib/ci-tools.nix:28-31`),
   `-p`/`nix shell` без флейка не разрешается, а `nix shell <flake>#…`
   каждый раз тянет вычисление флейка nixpkgs.

**Последствия.**

- `pwsh` появляется в `/run/current-system/sw/bin/` **только после**
  активации (`nixos-rebuild switch|boot`), а не после `build`: до неё
  бинарь существует лишь в замыкании сборки. Это важно для проверки —
  `nixos-rebuild build` доказывает сборку, но не наличие `pwsh` в PATH.
- Ни `director.ps1`, ни его тесты в этом репозитории не появляются: правка
  даёт **возможность** исполнения, а не сам набор. Прогон ps1-тестов —
  задача репозитория `metaagent-director`.
- `powershell` в `lib/ci-tools.nix` **остаётся**: PATH джобы раннера и
  системный PATH — разные контракты, и джоба не должна зависеть от того,
  активирован ли системный пакет на хосте. Дубля нет: один список —
  инструменты джобы, другая строка — инструмент хоста; при этом версия у
  обоих одна и та же (один `pkgs`).
- Обновление версии — транзитивно через `flake.lock`, как у любого
  nixpkgs-пакета; пина нет и не требуется (в отличие от 3x-ui, где пинится
  сторонний образ, R1.5).

**Проверка.**

```bash
nix eval .#nixosConfigurations.sapphira.config.environment.systemPackages \
  --apply 'ps: map (p: p.name) ps' | grep powershell     # → powershell-7.6.6
nix eval .#nixosConfigurations.otreca.config.environment.systemPackages \
  --apply 'ps: map (p: p.name) ps' | grep -c powershell   # → 0
nixos-rebuild build --flake .#sapphira                    # собирается
./result/sw/bin/pwsh -NoLogo -Command '$PSVersionTable.PSVersion'   # 7.6.6
```

Проверено 2026-10-27 в ветке `agent/powershell-env`: сборка
`nixos-rebuild build --flake .#sapphira` успешна, `pwsh` в собранной
системе — 7.6.6, у `otreca`/`atoridu`/`rydiwo`/`wsl` PowerShell в
`systemPackages` отсутствует (0 совпадений).

**Известное ограничение хоста (не дефект правки):** `nix flake check` из
`.ci/checks.sh` на sapphira **не доводится до конца**. Прогон 2026-10-27
дошёл до последнего шага — `checking NixOS configuration
'nixosConfigurations.sapphira'` — и был снят после ~30 минут: `Swap`
4.8 GiB занят полностью (0 B свободно), Mem 3.9/5.6 GiB занята живыми
сервисами (immich, opencode serve, herdr, nginx, gitea-раннер), то есть
вычисление уходит в трэшинг на 2 ядрах. До снятия `flake check` успел
проверить все остальные выходы флейка (`packages`, `nixosModules`,
`devShells`, `homeConfigurations` и конфигурации `default`, `atoridu`,
`rydiwo`, `otreca` — без ошибок; только rename-warnings nixpkgs).
Замена проверки — точечная: `nix eval
.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` для
**всех** шести хостов (все резолвятся) + полная сборка sapphira
`nixos-rebuild build` выше. Для этой правки это строже, чем `flake check`:
он не собирает системы, а сборка sapphira собирает ровно затронутое
замыкание.

**Откат.**

Удалить строку `environment.systemPackages = [ pkgs.powershell ];` из
`configurations/server.nix` + `nixos-rebuild switch`. Данных, состояния или
миграций нет — откат полный, побочных эффектов не остаётся.

**Связанное:** `lib/ci-tools.nix`, `modules/server/gitea-runner.nix`,
`devshells/default.nix`, `configurations/server.nix`, T59;
в репозитории `metaagent-director` — ps1-твин `director.ps1` и T30
(расхождения sh/ps1, которые были найдены чтением).
