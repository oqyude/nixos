# Task Manifest

**Session:** `metaagent-init-2026-10-09`
**Goal:** Установить metaagent, перенести накопленные данные (AGENTS.md, docs/arch/*) в структуру `.agent/`.
**Date:** 2026-10-09T20:30
**Project type:** `existing`

---

## Task Overview

| ID | Title | Type | Depends On | Status | Origin |
|---|---|---|---|---|---|
| T1 | A1: mobile.nix импортирует несуществующий lib/xlib.nix | fix | — | pending | user:direct |
| T2 | A2: убедиться, что nix flake check вообще запускается | verify | T1 | pending | user:direct |
| T3 | A3: явная финальная политика nftables на VDS | fix | — | pending | user:direct |
| T4 | B1: guard на несмонтированный носитель /mnt/services | security | — | pending | user:direct |
| T5 | B2: зафиксировать, что бэкапов в конфигурации нет | docs | — | pending | user:direct |
| T6 | C1: вернуть расследование 3x-ui, потерянное при откате | docs | — | pending | user:direct |
| T7 | C2: зафиксировать фактические версии панели и ядра 3x-ui | investigate | — | pending | user:direct |
| T8 | C3: убрать сервис автообновления 3x-ui | fix | — | pending | user:direct |
| T9 | C4: записать, что ядро Xray — состояние панели, а не Nix | docs | — | pending | user:direct |
| T10 | C5: решить судьбу reality443Forwarding | decision | — | pending | user:direct |
| T11 | D1: пробросы роутера — главный недостающий инвариант | docs | T3 | pending | user:direct |
| T12 | D2: зафиксировать 100.64.0.0 как Tailscale-адрес sapphira | docs | — | pending | user:direct |
| T13 | D3: убрать мёртвое правило firewall на sapphira | fix | T11 | pending | user:direct |
| T14 | E1: написать AGENTS.md в корне (с metaagent-шапкой) | docs | — | **completed** | user:direct |
| T15 | E2: выбрать проверки, которые заменят половину инвариантов | decision | T2 | pending | user:direct |
| T16 | E3: судьба 15 закомментированных модулей | refactor | T1 | pending | user:direct |

**Total tasks:** 16
**Pending:** 15
**In progress:** 0
**Completed:** 1
**Backlog (ждут ответа):** 23

---

## Задачи по группам

### A. Блокеры (T1–T3)

- **T1 (A1)** — критично: до правки `epral` мёртв. Цена правки: одна строка в `mobile.nix:12`.
- **T2 (A2)** — диагностика: ловит ли `flake check` проблему из T1.
- **T3 (A3)** — опасная зона: править `nftables` без `nft list ruleset` на otreca = риск отрезать SSH.

### B. Защита данных (T4–T5)

- **T4 (B1)** — 12+ сервисов на пустой БД после рестарта без диска. **Самый крупный фикс** (правка `mkStorageGuard` + 12 потребителей).
- **T5 (B2)** — запись в project-rules, не код. Ждёт ответа 5.6.

### C. 3x-ui: заморозить рабочее состояние (T6–T10)

- **T6 (C1)** — восстановить 200 строк из коммита `9974784` + дописать вердикт.
- **T7 (C2)** — сначала диагностика на sapphira и otreca, потом запинить тег.
- **T8 (C3)** — удалить `podman-update-3xui_app` + закомментированный таймер.
- **T9 (C4)** — запись в project-rules (R1.x).
- **T10 (C5)** — связано с вопросом 6.9.

### D. Сетевая граница (T11–T13)

- **T11 (D1)** — запись в project-rules (R1.3) + project-state.md.
- **T12 (D2)** — запись в project-rules (R1.4).
- **T13 (D3)** — мелкая чистка мёртвого правила.

### E. Документация (T14–T16)

- **T14 (E1)** — **выполнено** в этой инициализации.
- **T15 (E2)** — выбор из 7 кандидатов на CI-проверки (см. `analysis-report.md §5`).
- **T16 (E3)** — рефакторинг 15 модулей.

### F. Backlog (ждут ответа)

23 вопроса из `roadmap/sources.md` (F: 2.2, 2.5, 2.6, 3.2, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.3, 5.4, 5.5, 5.6, 6.6, 6.7, 6.8, 6.9, 7.4, 8.2, 8.4, 8.5, 8.6) — становятся задачами после ответа владельца.

---

## Зависимости

```
T1 → T2 → T15
T1 → T16
T3 → T11 → T13
```

Остальные задачи можно делать параллельно.
