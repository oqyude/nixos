# MetaAgent

MetaAgent — набор инструкций для AI-агента. Превращает хаотичное общение с агентом в структурированный процесс, в котором состояние проекта переживает любую сессию.

## Модель v3.0: цикл + команды

**Цикл** — последовательность фаз, которую агент проходит при работе с проектом:

```
INIT → ANALYSE → ROADMAP → [DESIGN] → DECOMPOSITION → EXECUTION → METASTATE → HANDOFF
```

DESIGN выполняется только для greenfield/scaffold-проектов. Для existing — пропускается.

**Команды** — on-demand инструкции, которые вызываются по явной просьбе пользователя:

| Команда | Что делает |
|---|---|
| `/adr` | Записать архитектурное решение в `.agent/decisions/` |
| `/red-team` | Попытаться сломать дизайн → `.agent/context/red-team-report.md` |
| `/risk-register` | Реестр допущений → `.agent/context/risk-register.md` |
| `/alt-arch` | Описать альтернативную архитектуру |
| `/invariant-tests` | Тесты-инварианты для ADR |

Команды **не обязательны**. Если не вызваны — не выполняются. Цикл работает без них.

## Что отличает MetaAgent от обычного общения с агентом

| Обычный агент | MetaAgent v3.0 |
|---|---|
| Контекст теряется при каждом новом разговоре | `.agent/` — полный слепок проекта: состояния, решения, задачи, результаты |
| Нет системы — агент действует ad-hoc | Чёткий жизненный цикл: INIT → … → HANDOFF |
| Нет места для ваших правил | `.agent/rules/project-rules.md` — читается перед каждой фазой |
| Результаты теряются между сессиями | **Request** — документированный результат каждой задачи (summary + коммиты + верификация) |
| Архитектурные решения не фиксируются | ADR, Risk Register, Red Team Review — по вызову пользователя |
| Контекст бесконтрольно растёт | Завершённые задачи архивируются, `.agent/` остаётся lean |
| Сложная конфигурация сессии (depth, фичи) | Никакой конфигурации. Цикл + команды — всё |

## Ключевые фичи v3.0

- **Цикл без конфигурации** — никакой шкалы depth, никаких интервью. Агент сам определяет тип проекта в ANALYSE.
- **Команды отдельно от цикла** — ADR, Red Team, Risk Register вызываются тогда, когда нужны.
- **Request как единица результата** — каждая задача завершается request-ом с diff-summary, коммитами и верификацией.
- **METASTATE** — по команде «обнови метасостояние»: ревью requests, обновление слепка проекта, подготовка `.agent/` для следующего агента.
- **Project State** — динамический слепок, обновляется при METASTATE. Следующий агент читает `.agent/` и не лезет в исходники.
- **Origin задач** — каждая задача знает, откуда пришла (roadmap, ADR, user, agent, decomposition).
- **Чекпоинты** (`checkpoints.json`) — позволяют возобновить сессию с любой фазы.
- **Ваши правила** — `.agent/rules/project-rules.md` — условия, которые агент соблюдает всегда.
- **Одна установка на всех** — `install.sh` (Unix и Git-Bash на Windows). PowerShell-версии нет намеренно: второй установщик — это второй список файлов, который молча расходится с `KIT-MANIFEST.tsv`.

## Быстрый старт

```bash
# Установить MetaAgent в ваш проект
./install.sh /path/to/your/project

# Или интерактивно:
./install.sh
```

Установка — это **весь INIT**, а не только копия исходников. После неё в
проекте есть:

| Что | Откуда |
|---|---|
| `.agent/src/` | кит, файл в файл по `KIT-MANIFEST.tsv` |
| `.agent/checkpoints.json` | литерал `PROTOCOLS/00_INIT.md` §0.8, по `TEMPLATES/schemas/checkpoints-schema.json` (`phases.init = completed`) |
| `.agent/rules/project-rules.md` | `TEMPLATES/project-rules.md` |
| `.agent/decisions/index.json` | пустой реестр ADR, по `TEMPLATES/schemas/decisions-index-schema.json` |
| `.temp/` + строка `.temp/` в `.gitignore` | — |
| `AGENTS.md` | `AGENTS.template.md` с подставленным `{VERSION}` |

Этого достаточно, чтобы цикл начался: протоколы читают `checkpoints.json`,
чтобы решить, может ли фаза выполняться. Директор для этого не нужен — ни
агенту, ни человеку.

**Что установщик не перезаписывает.** `checkpoints.json`, `rules/project-rules.md`,
`decisions/index.json`, `.gitignore` и `AGENTS.md` — данные проекта. Они
пишутся, только если файла нет, и не перезаписываются никогда, **ни на первом
прогоне, ни с `--update`**: `--update` — это «обнови `.agent/src/`», а не
«снеси моё состояние». Поэтому второй прогон установщика не меняет ни одного
файла (идемпотентность), а `AGENTS.md`, который уже лежит в проекте, остаётся
байт в байт — даже если он не про MetaAgent.

Любой AI-агент, работающий в проекте, автоматически получит полный контекст
через `AGENTS.md`.

### Установка на Windows

Отдельного PowerShell-установщика нет: `install.ps1` удалён 2026-11-06. Причина та же, что и у красной линии репозитория (PowerShell — не вторая реализация): второй установщик — это второй список файлов, который расходится с `KIT-MANIFEST.tsv` молча.

Windows-хост ставит кит из **Git-Bash** — он и так требуется всему парку (`~/.bashrc`-лаунчеры, `ssh`, `.metaagent`):

```bash
bash framework/install.sh /path/to/project          # первая установка
bash framework/install.sh --update /path/to/project # обновить .agent/src/
```

Хост **без Git-Bash** (голый Windows без git) поддерживаемого пути не имеет. Ему придётся либо поставить Git for Windows и работать из Git-Bash, либо скопировать содержимое `framework/` в `<project>/.agent/src/` вручную — без `KIT-MANIFEST.tsv`, который описывает кит, а не является его частью, — и создать вручную всё остальное, что делает INIT: `.agent/rules/project-rules.md`, `.agent/checkpoints.json` (литерал `PROTOCOLS/00_INIT.md` §0.8), `.agent/decisions/index.json`, `.temp/` со строкой в `.gitignore` и `AGENTS.md` по `AGENTS.template.md`. Это ручной обход, а не второй установщик: `install.sh` остаётся единственным установщиком.

## Версия

Текущая: **3.0.0** (см. `CHANGELOG.md`)

---

## MetaAgent (English)

MetaAgent is an instruction set for an AI agent that transforms chaotic agent interactions into a structured, predictable, and self-contained process.

### v3.0 model: loop + commands

**Loop** — the phases an agent goes through when working on a project:

```
INIT → ANALYSE → ROADMAP → [DESIGN] → DECOMPOSITION → EXECUTION → METASTATE → HANDOFF
```

DESIGN runs only for greenfield/scaffold projects. For existing — skipped.

**Commands** — on-demand instructions, invoked by the user explicitly:

| Command | What it does |
|---|---|
| `/adr` | Write an architecture decision to `.agent/decisions/` |
| `/red-team` | Try to break the design → `.agent/context/red-team-report.md` |
| `/risk-register` | Assumptions registry → `.agent/context/risk-register.md` |
| `/alt-arch` | Describe an alternative architecture |
| `/invariant-tests` | Invariant tests for an ADR |

Commands are **optional**. If not invoked — not executed. The loop works without them.

### Why MetaAgent over plain agent chat

| Plain agent | MetaAgent v3.0 |
|---|---|
| Context lost with every new conversation | `.agent/` — full project snapshot: state, decisions, tasks, results |
| No system — agent acts ad-hoc | Clear lifecycle: INIT → … → HANDOFF |
| No place for your rules | `.agent/rules/project-rules.md` — read before every phase |
| Results lost between sessions | **Request** — documented result per task (summary + commits + verification) |
| Architectural decisions lost | ADR, Risk Register, Red Team Review — invoked on demand |
| Context grows unboundedly | Completed tasks are archived, `.agent/` stays lean |
| Complex session configuration (depth, features) | No configuration. Loop + commands — that's it |

### Quick start

```bash
# Install MetaAgent into your project
./install.sh /path/to/your/project

# Or interactive:
./install.sh
```

An install is the **whole INIT**, not just a copy of the sources. Afterwards the
project has:

| What | From |
|---|---|
| `.agent/src/` | the kit, file for file per `KIT-MANIFEST.tsv` |
| `.agent/checkpoints.json` | the `PROTOCOLS/00_INIT.md` §0.8 literal, per `TEMPLATES/schemas/checkpoints-schema.json` (`phases.init = completed`) |
| `.agent/rules/project-rules.md` | `TEMPLATES/project-rules.md` |
| `.agent/decisions/index.json` | an empty ADR index, per `TEMPLATES/schemas/decisions-index-schema.json` |
| `.temp/` + a `.temp/` line in `.gitignore` | — |
| `AGENTS.md` | `AGENTS.template.md` with `{VERSION}` substituted |

That is enough for the loop to start: the protocols read `checkpoints.json` to
decide whether a phase may run. No director is needed for that — neither by an
agent nor by a human.

**What the installer never overwrites.** `checkpoints.json`,
`rules/project-rules.md`, `decisions/index.json`, `.gitignore` and `AGENTS.md`
are the project's data. They are written only when absent and are never
overwritten, **neither on a first run nor with `--update`**: `--update` means
"refresh `.agent/src/`", not "wipe my state". So a second run changes no file at
all (idempotent), and an `AGENTS.md` that already exists stays byte-identical —
even when it is not about MetaAgent.

Any AI agent working in the project automatically gets full context through
`AGENTS.md`.

### Installing on Windows

There is no PowerShell installer: `install.ps1` was removed on 2026-11-06. A second installer is a second file list that silently drifts from `KIT-MANIFEST.tsv` — and the repo's red line says PowerShell is never a second implementation.

A Windows host installs the kit from **Git-Bash**, which the fleet already requires (`~/.bashrc` launchers, `ssh`, `.metaagent`):

```bash
bash framework/install.sh /path/to/project          # first install
bash framework/install.sh --update /path/to/project # refresh .agent/src/
```

A host **without Git-Bash** has no supported path: either install Git for Windows and use Git-Bash, or copy the contents of `framework/` into `<project>/.agent/src/` by hand — without `KIT-MANIFEST.tsv`, which describes the kit rather than being part of it — and create the rest of INIT by hand: `.agent/rules/project-rules.md`, `.agent/checkpoints.json` (the `PROTOCOLS/00_INIT.md` §0.8 literal), `.agent/decisions/index.json`, `.temp/` with its line in `.gitignore`, and `AGENTS.md` from `AGENTS.template.md`. That is a manual workaround, not a second installer: `install.sh` stays the only one.
