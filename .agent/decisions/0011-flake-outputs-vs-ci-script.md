# ADR-0011: Форматтер — в devshell; проверки — в CI-скрипте, а не в output'ах флейка

**Статус:** accepted (редакция 2 — 2026-11-15, после перепроверки)

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

**Ревизия 2 — что на самом деле чинит эту поломку.**

Первая редакция винила закреплённый nixpkgs и утверждала, что «добавить
собственный derivation-вывод флейка нельзя». Перепроверка это опровергла:

| Вывод флейка                        | `nix flake check --no-build` | Итог |
|-------------------------------------|------------------------------|------|
| `formatter = pkgs.hello`            | `error: 'outPath' is not a valid system type` | **падает** |
| `formatter` = hand-written `derivation` (без nixpkgs) | та же ошибка, но в `«nix-internal»/derivation-internal.nix:50` | **падает** |
| `formatter` = derivation без атрибута `outPath` | `error: 'drvPath' is not a valid system type` | **падает** |
| `checks.x86_64-linux.hello = pkgs.hello` | `all checks passed!` | **работает** |
| `packages.x86_64-linux.hello = pkgs.hello` | `all checks passed!` | **работает** |
| control: без derivation-выводов    | `all checks passed!` | **работает** |

То есть поломка:

- **не зависит от nixpkgs** — воспроизводится на флейке вообще без инпутов,
  с derivation'ом, собранным руками;
- **не зависит от того, что объявлено** — nix 2.34.9 при проверке вывода
  `formatter` перебирает **имена атрибутов** derivation'а и пытается
  трактовать каждое как системный тип: `outPath` → «not a valid system
  type», а если убрать этот атрибут — следующий, `drvPath`. Это баг самого
  nix в обработке вывода `formatter`, а не особенность nixpkgs;
- **не задевает вывод `checks`** — derivation-выводы в `checks` флейк проверяет
  нормально. В этом же репозитории вывод `checks` уже есть и работает:
  `checks.x86_64-linux.deploy-schema` и `checks.x86_64-linux.deploy-activate`
  (приходят из deploy-rs) вычисляются и проходят.

**Решение.**

1. Output'а `formatter` у флейка **нет** — он роняет `nix flake check` на
   nix 2.34.9 (баг nix, воспроизводится без nixpkgs). Форматтер — devshell:
   `nix develop .#fmt --command treefmt` (treefmt + nixfmt + shfmt,
   конфиг — `treefmt.toml` в корне). `nix fmt` без output'а недоступен;
   это приемлемо, форматтер нужен редко.
2. Python-проверки живут в `.ci/checks.sh`, каждая как отдельный скрипт без
   зависимостей (`python3 .ci/tests/<script>.py .`) — один и тот же код
   гоняют и CI, и pre-commit-хук, и разработчик локально.
   Это **выбор, а не запрет**: derivation-вывод в `checks` технически
   работает, но (а) проверка в derivation видит только закоммиченный flake
   source, а не рабочее дерево — для pre-commit и локального цикла это
   неправильная семантика; (б) имя `checks` уже занято проверками
   deploy-rs (`deploy/default.nix`), а `//` в `flake.nix` отдал бы приоритет
   более позднему операнду — новые проверки молча вытеснили бы чужие.
3. Причина зафиксирована комментарием в `flake.nix` — чтобы следующий агент
   не «починил» это, не заметив поломки.

**Альтернативы и почему не выбраны.**

1. **Output `formatter` (writeShellScript / buildEnv).** Отклонено: роняет
   `nix flake check` — то есть ломает рабочий инвариант #2. Обойти баг nix
   нельзя: падает любой derivation в этом выводе.
2. **Output `checks.*` (runCommand с python).** Отклонено по причинам выше
   (семантика рабочего дерева и коллизия имён с deploy-rs), а не потому,
   что derivation-выводы запрещены.
3. **Output `apps.*` (writeShellApplication).** Отклонено: это тоже
   derivation, и в этом nixpkgs у `writeShellApplication` нет атрибута
   `program` — nix отвечает «app lacks attribute 'program'».
4. **Оставить репозиторий как есть.** Отклонено: проверки #10–#13 закрывают
   реальные классы поломок (расхождение DNS и vhost'ов, `listen.addr` с
   сетью вместо интерфейса, противоречия в метаданных `.agent`, ShellCheck),
   а форматтер страхует от дрейфа стиля.

**Последствия.**

- `nix fmt` недоступен; форматирование — `nix develop .#fmt --command treefmt`.
  Форматирование не навязывается при коммите: старые файлы не трогаются.
- `nix flake check` проверяет вычисление outputs (как и раньше) — новых
  проверок он не добавляет; они живут в `.ci/checks.sh`.
- Известные расхождения DNS↔vhost вынесены в
  `.ci/tests/known-domain-gaps.txt`: проверка падает на **новых**
  расхождениях, а не на исторических.
- Когда nix починят обработку вывода `formatter`, output можно вернуть —
  это отдельная задача. Проверяется одной командой (ниже).

**Проверка (воспроизведение поломки и границы).**

```bash
mkdir /tmp/probe && cd /tmp/probe
cat > flake.nix <<'NIX'
{
  outputs = { self }: {
    formatter = derivation {
      name = "fmt";
      system = "x86_64-linux";
      builder = "/bin/sh";
      args = [ "-c" "echo hi" ];
    };
  };
}
NIX
nix flake check     # → "'outPath' is not a valid system type"
                    #   (nix 2.34.9, баг, nixpkgs не участвует)
```

Тот же флейк с

```nix
    checks.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
```

проходит: `all checks passed!`.

**Связанное:** `flake.nix`, `devshells/default.nix`, `treefmt.toml`,
`.ci/checks.sh`, T62, R1.16 (декларация ≠ runtime — та же мысль, другой
слой).
