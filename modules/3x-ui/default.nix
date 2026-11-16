{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules."3x-ui";
  # Имя контейнера панели 3x-ui (modules/containers/3x-ui.nix:59).
  panelContainer = "3xui_app";
  # Путь к БД панели ВНУТРИ контейнера: bind-mount
  # `${services-nodes}/<host>/3x-ui/db` → `/etc/x-ui`
  # (modules/containers/3x-ui.nix:85). Внутри контейнера путь одинаков на
  # otreca и sapphira, поэтому пакет обёртки не зависит от хоста.
  panelDbUri = "file:/etc/x-ui/x-ui.db?mode=ro";
  # Читает значение одной настройки панели из таблицы `settings`.
  # Печатает ТОЛЬКО значение (пустую строку, если настройки нет): токен
  # не должен утекать ни в stderr, ни в argv, ни в журнал.
  readSettingPy = ''
    import sqlite3, sys
    con = sqlite3.connect(sys.argv[1], uri=True)
    row = con.execute("select value from settings where key = ?", (sys.argv[2],)).fetchone()
    sys.stdout.write((row[0] if row and row[0] else "") + "\n")
  '';
in
{
  options.modules."3x-ui" = {
    reconfig = lib.mkOption {
      type = lib.types.package;
      description = "Скрипт `reconfig`, который POST'ит /panel/api/server/restartXrayService в локальный apiToken панели. Записывает `config.json` из БД и рестартит xray. Значения `PANEL_BASE`/`PANEL_TOKEN` приходят из обёртки `reconfigRunner`. R1.18 (.agent/rules/project-rules.md).";
      default = pkgs.writeShellApplication {
        name = "reconfig";
        # grep нужен для проверки ответа панели; он берётся из own runtimeInputs,
        # а не из PATH окружения юнита — иначе скрипт падает с
        # «grep: command not found».
        runtimeInputs = [
          pkgs.curl
          pkgs.gnugrep
        ];
        text = ''
          #!/usr/bin/env bash
          # Перегенерировать config.json на 3x-ui-ноде и рестартнуть xray.
          #
          # Проблема, которую лечит этот скрипт (R1.18, 2026-10-21):
          #   правка REALITY-инбаунда в UI панели меняет БД, но
          #   config.json НЕ переписывается — панель пишет его только
          #   при старте контейнера и через POST /server/restartXrayService.
          #   Сервер продолжает крутить старый файл -> ссылки у клиентов
          #   ломаются молча. Этот скрипт дёргает нужный эндпоинт.
          #
          # Использование (обычно вызывается обёрткой `reconfigRunner`,
          # которая берёт PANEL_BASE/PANEL_TOKEN из БД панели):
          #   PANEL_URL=https://pubray1.zeroq.su \
          #   PANEL_BASE=/pubray PANEL_TOKEN=<api_token> \
          #     reconfig
          set -euo pipefail

          : "''${PANEL_URL:?PANEL_URL is required (e.g. https://pubray1.zeroq.su or https://x.zeroq.su)}"
          : "''${PANEL_BASE:=/}"
          : "''${PANEL_TOKEN:?PANEL_TOKEN is required}"

          BASE="''${PANEL_BASE%/}"
          URL="''${PANEL_URL%/}''${BASE}/panel/api/server/restartXrayService"

          # Токен нельзя класть в argv: `ps` показывает чужие процессы
          # всем локальным пользователям. Заголовок уходит в curl через
          # stdin (`--config -`), поэтому в списке процессов его нет.
          # В config-файле curl кавычки и обратный слэш экранируются,
          # поэтому токен вне безопасного набора не поддерживается —
          # проверяем заранее и падаем внятно.
          if [[ "$PANEL_TOKEN" =~ [^A-Za-z0-9._~+/=-] ]]; then
              echo "[reconfig] ERROR: PANEL_TOKEN contains characters unsupported by the curl config transport" >&2
              exit 1
          fi

          echo "[reconfig] POST $URL" >&2
          RESPONSE="$(printf 'header = "Authorization: Bearer %s"\n' "$PANEL_TOKEN" \
            | curl -sS --max-time 60 -k --config - -X POST "$URL")"

          if ! printf '%s' "$RESPONSE" | grep -q '"success":true'; then
              echo "[reconfig] ERROR: $RESPONSE" >&2
              exit 1
          fi

          echo "[reconfig] OK: xray regenerated and restarted" >&2
          printf '%s\n' "$RESPONSE"
        '';
      };
      defaultText = lib.literalExpression "writeShellApplication { name = \"reconfig\"; }";
    };

    reconfigRunner = lib.mkOption {
      type = lib.types.package;
      description = "Обёртка юнита `3xui-reconfig`: читает `webBasePath` и `apiToken` из БД панели 3x-ui в рантайме и передаёт их скрипту `reconfig` через PANEL_BASE/PANEL_TOKEN. Секретов в nix store нет, в журнал токен не пишется (только длина). R1.18.";
      default = pkgs.writeShellApplication {
        name = "reconfig-runner";
        runtimeInputs = [ pkgs.podman ];
        text = ''
          # Обёртка юнита 3xui-reconfig: достаёт из БД панели 3x-ui значения
          # `webBasePath` и `apiToken` и передаёт их скрипту `reconfig` через
          # переменные окружения PANEL_BASE / PANEL_TOKEN.
          #
          # Почему так (2026-11-16):
          #   * в юнитах стояли ЛИТЕРАЛЫ «PANEL_BASE=@base» и
          #     «PANEL_TOKEN=@api_token», которые никто не подставлял: curl
          #     уходил на «https://pubray1.zeroq.su@base/panel/api/...» и
          #     падал с «curl: (6) Could not resolve host: base».
          #     Юнит не работал НИКОГДА — ни на otreca, ни на sapphira;
          #   * webBasePath и apiToken — это СОСТОЯНИЕ панели (таблица
          #     `settings` БД), а не константы: база веб-панели может
          #     смениться, токен ротируется.
          #
          # Токен живёт только в рантайме: в nix store его нет, в журнал
          # не пишется (в журнал уходит только длина), в argv не попадает.

          CONTAINER="${panelContainer}"
          DB_URI="${panelDbUri}"

          log() {
              printf '[reconfig] %s\n' "$*" >&2
          }

          if ! podman container exists "$CONTAINER" >/dev/null 2>&1; then
              log "ERROR: container '$CONTAINER' not found — the 3x-ui panel is not running, or it is not visible to this podman instance (podman ps -a)"
              exit 1
          fi

          PANEL_BASE="$(
              podman exec "$CONTAINER" python3 -c '${readSettingPy}' "$DB_URI" webBasePath
          )" || {
              log "ERROR: cannot read webBasePath from the panel database ($CONTAINER:$DB_URI)"
              exit 1
          }

          PANEL_TOKEN="$(
              podman exec "$CONTAINER" python3 -c '${readSettingPy}' "$DB_URI" apiToken
          )" || {
              log "ERROR: cannot read apiToken from the panel database ($CONTAINER:$DB_URI)"
              exit 1
          }

          if [ -z "$PANEL_TOKEN" ]; then
              log "ERROR: apiToken is empty in the settings table of the panel database ($CONTAINER)"
              exit 1
          fi

          TOKEN_LEN=''${#PANEL_TOKEN}
          log "panel database: webBasePath='$PANEL_BASE' apiToken received ($TOKEN_LEN chars)"

          export PANEL_BASE PANEL_TOKEN
          exec ${lib.getExe cfg.reconfig}
        '';
      };
      defaultText = lib.literalExpression "writeShellApplication { name = \"reconfig-runner\"; }";
    };
  };
}
