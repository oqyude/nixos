# ADR-0011: Проверки и форматтер — в CI-скрипте и devshell, а не в output'ах флейка

**Статус:** accepted

**Дата:** 2026-11-15

**Контекст.**

Гигиена репозитория (T62) предполагала, что статические проверки удобнее
запускать через `nix flake check`, а форматтер — через `nix fmt`. Для этого
флейк получил бы output'ы `checks.*` (деривации с python-скриптами) и
`formatter` (treefmt + nixfmt + shfmt).

Измерение (WSL, nix 2.34.9, закреплённый nixpkgs `f4a03c0`):

```
$ nix flake check
checking flake output 'formatter'...
error: 'outPath' is not a valid system type,
       at «github:NixOS/nixpkgs/f4a03c00…»/lib/customisation.nix:423:11
```

Поломка **не зависит от того, что именно объявлено**:

- `formatter = pkgs.hello` — падает так же;
- `formatter = pkgs.writeShellScript …` и `pkgs.buildEnv { … }` — так же;
- `pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux` и
  `pkgs = import inputs.nixpkgs { system = "x86_64-linux"; }` — одинаково;
- ветка `nixos-unstable` против закреплённого ревизии — одинаково;
- lock-файл репозитория против свежего — одинаково;
- воспроизводится на **минимальном флейке с одним инпутом nixpkgs**;
- `nix build .#formatter` при этом работает — падает именно проверка
  derivation-вывода внутри `nix flake check`.

При этом `nix flake check` на dev-ветке **проходит**: там `checks.*` приходят
из deploy-rs (`inputs.deploy-rs.lib.<system>.deployChecks`), и такие
деривации проверку проходят.

То есть добавить собственный derivation-вывод флейка на этом nixpkgs нельзя:
проверка упала бы у владельца на следующем же `nix flake check`, а это
существующий CI-инвариант (#2 в `.ci/checks.sh`).

**Решение.**

1. Output'ов `formatter` и `checks` у флейка **нет**.
2. Форматтер — devshell: `nix develop .#fmt --command treefmt`
   (treefmt + nixfmt + shfmt, конфиг — `treefmt.toml` в корне). Форматтер
   нужен редко, а `nix fmt` без output'а недоступен.
3. Проверки — `.ci/checks.sh`, каждая как отдельный python-скрипт без
   зависимостей (`python3 .ci/tests/<script>.py .`): один и тот же код
   гоняют и CI, и pre-commit-хук, и разработчик локально.
4. Причина зафиксирована комментарием в `flake.nix` — чтобы следующий агент
   не «починил» это, не заметив поломки.

**Альтернативы и почему не выбраны.**

1. **Output `formatter` (writeShellScript / buildEnv).** Отклонено: роняет
   `nix flake check` — то есть ломает рабочий инвариант.
2. **Output `checks.*` (runCommand с python).** Отклонено по той же причине.
   Побочно: в этом nixpkgs `checks` из `deploy/default.nix` уже занимает это
   имя, а `//` в `flake.nix` отдал бы приоритет более позднему операнду —
   то есть мои проверки молча вытеснялись бы проверками deploy-rs.
3. **Output `apps.*` (writeShellApplication).** Отклонено: это тоже
   derivation, и в этом nixpkgs у `writeShellApplication` нет атрибута
   `program` — nix отвечает «app lacks attribute 'program'».
4. **Оставить репозиторий как есть.** Отклонено: проверки #10–#12 закрывают
   реальные классы поломок (расхождение DNS и vhost'ов, `listen.addr` с
   сетью вместо интерфейса, противоречия в метаданных `.agent`), а
   форматтер страхует от дрейфа стиля (все 137 .nix-файлов уже nixfmt-чистые).

**Последствия.**

- `nix fmt` недоступен; форматирование — `nix develop .#fmt --command treefmt`.
  Форматирование не навязывается при коммите: старые файлы не трогаются.
- `nix flake check` проверяет только вычисление outputs (как и раньше) —
  новых проверок он не добавляет; они живут в `.ci/checks.sh`.
- Известные расхождения DNS↔vhost вынесены в
  `.ci/tests/known-domain-gaps.txt`: проверка падает на **новых**
  расхождениях, а не на исторических.
- Когда nixpkgs переедет на ревизию, где проверка derivation-выводов
  работает, output'ы можно вернуть — это отдельная задача.

**Проверка (воспроизведение поломки).**

```bash
mkdir /tmp/probe && cd /tmp/probe
cat > flake.nix <<'NIX'
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/f4a03c008967841f2a0b3cb7c436fc6fc31671f6";
  outputs = inputs:
    let pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in { formatter = pkgs.hello; };
}
NIX
nix flake check     # → "'outPath' is not a valid system type"
```

**Связанное:** `flake.nix`, `devshells/default.nix`, `treefmt.toml`,
`.ci/checks.sh`, T62, R1.16 (декларация ≠ runtime — та же мысль, другой
слой).
