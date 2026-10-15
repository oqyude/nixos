# ADR-0004: Имя systemd-юнита при переопределении upstream-модуля

**Статус:** accepted

**Дата:** 2026-10-15

**Контекст.**

`services.gitea-actions-runner` (nixpkgs) регистрирует юнит не через
`systemd.services.<имя> = …`, а через `nameValuePair`:

```nix
# nixos/modules/services/continuous-integration/gitea-actions-runner.nix:195
nameValuePair "gitea-runner-${escapeSystemdPath name}" { … }
```

`escapeSystemdPath` заменяет `-` на **литеральный** `\x2d`. Для
`name = "ci-sapphira"` реальный ключ — `gitea-runner-ci\x2dsapphira`, где
между `ci` и `dsapphira` стоит обратный слэш, а не дефис.

Обе формы рендерятся в **один и тот же файл**
`gitea-runner-ci-sapphira.service`, но это **два разных атрибута**.
Репозиторий писал `systemd.services.gitea-runner-ci-sapphira.unitConfig = …`
(обычный дефис) и получал второй, пустой юнит — фантом.

Последствие: в вычисленном `systemd.services` оказывались **171** ключ, среди
которых одновременно существовали:

```
gitea-runner-ci-sapphira      ← фантом репозитория: только unitConfig, без ExecStart
gitea-runner-ci\x2dsapphira   ← настоящий юнит upstream: ExecStart, User, StateDirectory…
```

Фантом выигрывал рендер, и systemd отказывался запускать юнит:

```
gitea-runner-ci-sapphira.service: Service has no ExecStart=, ExecStop=, or SuccessAction=. Refusing.
```

Юнит не стартовал с **2026-10-14 16:25** до **2026-10-15 01:23** — 12 часов
молчания, при этом система собиралась и переключалась без ошибок.

**Три неверных диагноза подряд** — каждый закреплял баг, а не лечил его:

1. `a807701` — «нет `serviceConfig`, юнит неполный» (проблема была не в этом).
2. `e6e82b8` — «`systemd.services.X.serviceConfig.Y = Z` **молча заменяет**
   upstream-подмодуль; `[Unit]` мержится, `[Service]` — нет». На основании
   этого вывода `serviceConfig` был объявлен непригодным, а cgroup caps
   отложены «на потом» в systemd drop-in. **Вывод ложный**: с правильным
   ключом `serviceConfig` мержится штатно.
3. Переход на `unitConfig` — тот же фантом по той же причине (неверное имя),
   просто выглядел «безобиднее».

Скрытность усугублялась тем, что `service-runner.nix` NixOS падает на
`attribute 'ExecStart' missing` лишь при форсировании этого конкретного
атрибута; обычная сборка проходит.

**Рассматриваемые альтернативы:**

1. **Верное имя атрибута** — `systemd.services.${unitKey}` с
   `unitKey = "gitea-runner-ci\\x2dsapphira"`, сливается с upstream.
2. **`lib.mkForce`** на верхнеуровневые опции — объявляет «я знаю, что делаю»,
   но не устраняет фантомный второй юнит; оставляет два юнита на один файл.
3. **systemd drop-in** — `/etc/systemd/system/…service.d/override.conf` в
   обход Nix. Работает, но выносит конфигурацию из репозитория и не лечит
   причину: подтверждено, что `serviceConfig` с правильным ключом мержится.

**Решение:** вариант 1 — правильное имя атрибута, плюс «растяжка» в виде
`assertions`, падающей при отсутствии `ExecStart`.

**Обоснование:** единственный вариант, который устраняет причину, оставляет
юнит целиком в Nix-репозитории и открывает (а не закрывает) возможность
конфигурировать `serviceConfig`. Drop-in был бы обходным путём, ошибочно
подтверждающим ложный вывод `e6e82b8`.

**Последствия:**

- Позитивные: юнит получил `ExecStart` и стартовал впервые за 12 дней;
  `serviceConfig` доказанно мержится; cgroup caps снова можно задавать
  штатно, без drop-in'а.
- Негативные: имя юнита на диске содержит литеральный `\x2d`, поэтому
  `systemctl show gitea-runner-ci-sapphira` **возвращает значения по
  умолчанию, а не реальные** — looked-up имя не совпадает. Диагностировать
  можно только читая файл юнита или запрашивая по точному имени.
- Риски: `escapeSystemdPath` недоступен через `lib.utils` /
  `pkgs.lib.utils` / `config.lib.utils` в этом флейке, поэтому ключ задан
  литералом и может разъехаться при переименовании. Отсюда `assertions` как
  страховка.

**Смежная находка (не часть решения, но обязательна к фиксации).**
`ConditionPathIsMountPoint` — директива секции **`[Unit]`**, однако
`mkStorageGuard` (`lib/xlib/helpers.nix:180`) отдаёт её потребителям как
`serviceConfig`, то есть в `[Service]`, где systemd её **не читает**. На
sapphira это подтверждено построчно в отрендеренных юнитах: у `gitea`
секция `[Service]` начинается со строки 5, а `ConditionPathIsMountPoint`
лежит на строке 14. Гвард мёртв на **13 systemd-юнитах / 12 сервисах**.
Это и есть задача **T4** (оставлена `pending`).

Номера строк и масштаб перепроверены 2026-10-15T03:00 на текущем
`/etc/systemd/system/gitea.service`: `[Unit]` = 1, `[Service]` = 5,
`ConditionPathIsMountPoint` = 14, `[Install]` = 61. Прежние «6 и 15» и «10
сервисов» были неточны — юнит с тех пор перерендеривался, а пересчёт
потребителей дал 13 юнитов, а не 10. Числа строк зависят от состава
секции `[Unit]`, поэтому проверять гвард следует по **наличию директивы в
`[Service]`**, а не по номерам строк.

**Invariant (R1.14).** Переопределяя systemd-юнит, который порождает
upstream-модуль, имя атрибута `systemd.services.<…>` должно **побайтово**
совпадать с тем, что модуль передаёт в `nameValuePair`. Проверка:

```bash
nix eval --raw .#nixosConfigurations.sapphira.config.systemd.services \
  --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' \
  | grep -i <имя-юнита>
```

Если в выводе одновременно есть экранированная и неэкранированная формы —
значит появился фантом, и юнит не запустится. Быстрый симптом в проде:
`systemctl show <юнит> -p ExecMainStartTimestamp` пуст, а в журнале
`Service has no ExecStart=… Refusing.`