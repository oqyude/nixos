# Протокол 00: Инициализация (INIT)

## Цель

Подготовить `.agent/` в целевом репозитории: установить исходники MetaAgent,
создать структуру директорий, создать `checkpoints.json`,
`rules/project-rules.md`, `decisions/index.json`, `.temp/` с записью в
`.gitignore`, и `AGENTS.md`.

INIT выполняется **один раз** в начале работы с проектом. Если `.agent/` уже
существует и инициализирован — пропускается.

**Весь INIT выполняет `install.sh`** — единственный установщик кита. Этот
протокол описывает ровно то, что делает скрипт; тест
`tests/sh-framework-install-init.sh` проверяет соответствие, и расхождение
между этим файлом и скриптом — дефект, а не «примерно то же».

**Два правила записи, и они разные:**

| Что | Правило |
|---|---|
| `.agent/src/` — копия кита | перезаписывается **только** с `--update` |
| `checkpoints.json`, `rules/project-rules.md`, `decisions/index.json`, `.gitignore`, `AGENTS.md` | **данные проекта**: пишутся, только если файла нет; не перезаписываются **никогда** — ни на первом прогоне, ни с `--update` |

## Вход

- Целевой репозиторий (путь или текущая директория)
- `VERSION` — версия MetaAgent в форме `MAJOR.MINOR.PATCH`. Другая форма —
  отказ установщика (exit 1): `VERSION` попадает в `checkpoints.json`, а
  `TEMPLATES/schemas/checkpoints-schema.json` требует именно эту форму
- Опционально: существующий `.agent/` (если обновление)

## Шаги

### 0.1. Определить целевой репозиторий

Если не указан явно — текущая рабочая директория. Если указан как URL —
клонировать во временную директорию, дальше работать с копией.

### 0.2. Проверить существующий `.agent/`

Если `.agent/` существует:

- Прочитать `.agent/checkpoints.json` → `metaagent_version`
- Если `metaagent_version == VERSION` → INIT уже выполнен, выйти
- Если версия старше → запустить `bash install.sh --update` (Unix или Git-Bash
  на Windows), затем выйти. `--update` переустанавливает `.agent/src/` **и
  создаёт отсутствующие INIT-артефакты**; существующие он не трогает, поэтому
  на проекте, инициализированном раньше, он дописывает ровно недостающее
- Если `.agent/` есть, но `checkpoints.json` отсутствует → продолжить INIT
  (создать checkpoints)

Если `.agent/` не существует → продолжить INIT.

### 0.3. Создать структуру `.agent/`

Создать директории (ровно этот набор; лишних нет, пропущенных нет):

```
.agent/
  src/                 # исходники MetaAgent (копируются из METAAGENT_SRC)
  rules/
  decisions/
  tasks/
    backlog/
  context/
  requests/
    active/
    archive/
  roadmap/
    archive/
  archive/
    tasks/
    decisions/
    requests/
    checkpoints/
.temp/                 # в корне проекта, не внутри .agent/
```

### 0.4. Создать `.temp/` и записать его в `.gitignore`

Если `.temp/` не существует — создать `.temp/` в корне целевого репозитория.

Добавить в `.gitignore` строку `.temp/`:

- `.gitignore` нет → создать с одной строкой `.temp/`
- строка уже есть → **ничего не делать** (файл не переписывается; второй
  прогон установщика не меняет в нём ни байта)
- строки нет → **дописать** в конец, сохранив все существующие строки как
  есть. Проверка «уже есть» сравнивает строки без `\r`: `.gitignore` с CRLF
  иначе выглядит так, будто `.temp/` в нём нет (см. `AGENTS.md`, ловушка 2), и
  установщик дописывал бы дубликат на каждом прогоне

### 0.5. Скопировать исходники MetaAgent

Скопировать в `.agent/src/` — это **ровно набор `KIT-MANIFEST.tsv`, файл в
файл** (38 файлов):

- `GUIDE.md`
- `BOUNDARIES.md`
- `CHANGELOG.md`
- `WORKFLOW.md`
- `README.md`
- `AGENTS.template.md`
- `VERSION`
- `PROTOCOLS/`
- `COMMANDS/`
- `TEMPLATES/`
- `FUTURE/`
- `install.sh`

Существующие файлы в `.agent/src/` не перезаписывать (только с явным
`--update`).

### 0.6. Создать `.agent/rules/project-rules.md`

Если файла нет — создать копией `TEMPLATES/project-rules.md`. Существующий
файл не трогать: это правила пользователя.

### 0.7. Создать `.agent/decisions/index.json`

Если файла нет — создать реестр ADR в форме
`TEMPLATES/schemas/decisions-index-schema.json`:

```json
{
  "version": "3.0",
  "decisions": []
}
```

`version` — из перечня схемы (`"2.0"` | `"3.0"`), `decisions` — список; на
старте он пуст. `created_at`/`updated_at` схема допускает, но не требует:
пустому реестру нечего датировать, а лишняя метка времени сделала бы файл
другим на каждом прогоне.

### 0.8. Инициализировать `checkpoints.json`

Если файла нет — создать `.agent/checkpoints.json`:

```json
{
  "metaagent_version": "3.0.0",
  "session_id": "<uuid>",
  "target_repo": "<путь>",
  "goal": null,
  "project_type": null,
  "phases": {
    "init": "completed",
    "analyse": "pending",
    "roadmap": "pending",
    "design": "pending",
    "decomposition": "pending",
    "execution": "pending",
    "metastate": "pending",
    "handoff": "pending"
  },
  "tasks": [],
  "last_updated": "<timestamp>"
}
```

Файл обязан удовлетворять `TEMPLATES/schemas/checkpoints-schema.json`: восемь
фаз из перечня `phases`, статусы из перечня
`pending | in_progress | completed | failed | skipped`, `metaagent_version` в
форме `MAJOR.MINOR.PATCH`, и **ни одного ключа, которого схема не объявляет**.

`metaagent_version` — из `VERSION`; `session_id` — UUID; `target_repo` —
абсолютный путь цели; `last_updated` — ISO 8601 UTC.

Собственный `.agent/checkpoints.json` этого репозитория **не является
образцом**: в нём статусы вида `"completed (2026-10-27: ...)"`, то есть
свободный текст, и схеме он не удовлетворяет. Образец — схема + литерал выше.

Поля `goal` и `project_type` остаются `null` до фазы ANALYSE (goal может быть
задан пользователем заранее — тогда заполнить сразу).

### 0.9. Создать `AGENTS.md` в корне

Если `AGENTS.md` в корне проекта отсутствует — создать его из
`AGENTS.template.md`, подставив `{VERSION}` (единственный плейсхолдер
шаблона). Шаблон — **единственное** описание того, что написано в
`AGENTS.md`; второй копии текста в установщике нет.

Если `AGENTS.md` существует — **не перезаписывать никогда**, ни на первом
прогоне, ни с `--update`, и не спрашивать подтверждения. Файл может быть
собственным файлом владельца или файлом более старого MetaAgent с локальными
правками; установщик не умеет их различать, а перезапись необратима. Владелец
решает сам, заменить его или дописать.

## Выход

- `.agent/` с полной структурой
- `.agent/src/` с актуальными исходниками MetaAgent
- `.agent/rules/project-rules.md`
- `.agent/decisions/index.json`
- `.agent/checkpoints.json` со `session_id` и `phases.init = "completed"`
- `AGENTS.md` в корне проекта
- `.temp/` в корне + `.gitignore` с `.temp/`

## Критерии завершения

- [ ] `.agent/` содержит все обязательные директории
- [ ] `.agent/src/` содержит GUIDE.md, PROTOCOLS/, COMMANDS/, TEMPLATES/, VERSION
- [ ] `.agent/rules/project-rules.md` существует
- [ ] `.agent/decisions/index.json` разбирается как JSON и удовлетворяет своей схеме
- [ ] `.agent/checkpoints.json` разбирается как JSON и удовлетворяет `checkpoints-schema.json`
- [ ] `AGENTS.md` присутствует в корне
- [ ] `.temp/` существует и `.gitignore` содержит `.temp/`
- [ ] второй прогон установщика не меняет ни одного файла (идемпотентность)
