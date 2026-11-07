# 010: OMO Integration — MetaAgent как слой метаданных проекта

## Статус: черновик (планирование)

## Проблема

MetaAgent v3.0 имеет структурированный `.agent/` с правилами, решениями, задачами, контекстом и командами on-demand. Но нет исполняющего движка, который гарантированно читает эти артефакты перед работой. OMO (oh-my-opencode) — идеальный движок, но его состояние живёт только локально в `.omo/`.

## Идея

`.agent/` — канонический слой метаданных проекта (коммитится в репозиторий).
`.omo/` — операционный слой (только локально, сессии, планы выполнения).

OMO читает `.agent/` перед работой, пишет в `.agent/` после работы.

## Разделение ответственности

| Аспект | `.agent/` (MetaAgent) | `.omo/` (OMO) |
|--------|----------------------|----------------|
| Persistence | Коммитится в репозиторий | Только локально |
| Содержимое | Rules, ADRs, task manifest, контекст, requests, roadmap | Boulder, планы, кэш сессий |
| Аудитория | Любой AI-агент (Claude, GPT, OMO) | Только OMO |
| Время жизни | Всё время проекта | Сессия |

## Интеграционные точки

### 1. Pre-execution Hook (самое важное)

Перед тем как Sisyphus начинает работу:
1. Проверить `.agent/rules/project-rules.md`
2. Если есть — прочитать, добавить в system prompt как constraints
3. Проверить `.agent/decisions/index.json`
4. Если есть релевантные ADR — добавить как context
5. Проверить `.agent/tasks/manifest.json`
6. Если есть pending задачи — предложить их перед новыми
7. Проверить `.agent/context/project-state.md` — актуальный слепок
8. Проверить `.agent/requests/active/` — если есть ready_for_review, предложить METASTATE

### 2. Todo-манифест sync

OMO todowrite ↔ `.agent/tasks/manifest.json`:

- **PUSH**: задача завершена OMO → обновить `.agent/tasks/manifest.json` (status: completed) + создать request
- **PULL**: OMO стартует → прочитать `.agent/tasks/manifest.json`
- Конфликты: `last_updated` — кто позже, тот прав

### 3. ADR Creation Hook

После архитектурного решения от Oracle:
1. Oracle выдал рекомендацию
2. OMO: "Записать как ADR?" (вызов команды `/adr`)
3. При подтверждении — `.agent/decisions/NNN-slug.md` + обновить `index.json`

### 4. Skill: agent-metadata

Новый OMO skill, дающий агенту инструкции по работе с `.agent/`:

```
load_skills=["agent-metadata"]
```

Skill содержит:
- Структуру `.agent/` и обязательные поля
- Цикл фаз (INIT → ANALYSE → ROADMAP → DESIGN → DECOMPOSITION → EXECUTION → METASTATE → HANDOFF)
- Команды on-demand (adr, red-team, risk-register, alt-arch, invariant-tests)
- Правила валидации
- Шаблоны

### 5. Checkpoint Integration

При старте сессии OMO читает `.agent/checkpoints.json`:

```json
{
  "metaagent_version": "3.0.0",
  "session_id": "ses_...",
  "goal": "...",
  "project_type": "existing | greenfield | scaffold",
  "phases": { ... },
  "last_task_id": "T3",
  "context_hashes": {
    "rules": "sha256_of_rules",
    "decisions": "sha256_of_decisions_index"
  }
}
```

`context_hashes` — если rules изменились с прошлой сессии → OMO перечитывает.

## Протоколы: OMO-aware vs Standalone

| Фаза | OMO-режим | Standalone-режим |
|------|-----------|-------------------|
| INIT | OMO создаёт `.agent/` | install.sh/ps1 |
| ANALYSE | explore + librarian → `.agent/context/` | Агент сам сканирует |
| DESIGN | Oracle пишет design-report, пользователь вызывает /adr | Агент пишет design-report |
| DECOMPOSITION | todowrite sync → `.agent/tasks/manifest.json` | Ручное создание |
| EXECUTION | OMO build/test/commit + request | То же |
| METASTATE | OMO: ревью requests → архивация → handoff-summary | Агент вручную |
| HANDOFF | `.agent/checkpoints.json` финализируется | То же |

## Что не меняется

- BOUNDARIES.md — концепция валидна
- Архивация (HANDOFF) — остаётся
- **Depth scale убрана в v3.0** — больше нет порогов depth для команд. Команды вызываются явно.
- Разделение meta/exec — OMO берёт обе роли (Sisyphus как meta, deep/quick как exec)
- Команды (`/adr`, `/red-team`, ...) — загружаются как skills, доступны OMO по явному вызову

## FUTURE планы MetaAgent в контексте OMO

- FUTURE/001 (multi-agent workers) — OMO уже умеет делегировать (explore, librarian, oracle)
- FUTURE/002 (coordination server) — не нужен, MCP + background tasks заменяют
- FUTURE/003 (.temp/) — уже частично в MetaAgent, доинтегрировать

## Открытые вопросы

- Как часто OMO должен синхронизировать `.agent/tasks/manifest.json`?
- Нужна ли JSON Schema валидация при записи в `.agent/`?
- Как быть если `.agent/rules/project-rules.md` конфликтует с OMO system prompt?
- Стоит ли делать двухсторонний sync или только OMO → .agent?
- Как обрабатывать parallel writes от нескольких OMO-сессий?

## Зависимости

- MetaAgent v3.0 (текущая версия, упрощённая модель: цикл + команды)
- OMO с поддержкой pre-execution hooks
- Skill system для agent-metadata
