{ config, lib, pkgs, ... }:
let
  cfg = config.modules."3x-ui";
in
{
  options.modules."3x-ui" = {
    reconfig = lib.mkOption {
      type = lib.types.package;
      description = "Скрипт `reconfig`, который POST'ит /panel/api/server/restartXrayService в локальный apiToken панели. Записывает `config.json` из БД и рестартит xray. R1.18 (.agent/rules/project-rules.md).";
      default = pkgs.writeShellApplication {
        name = "reconfig";
        runtimeInputs = [ pkgs.curl ];
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
          # Использование:
          #   PANEL_URL=https://x.zeroq.su \
          #   PANEL_BASE=/pubray PANEL_TOKEN=<api_token> \
          #     reconfig
          set -euo pipefail

          : "''${PANEL_URL:?PANEL_URL is required (e.g. https://127.0.0.1:2049)}"
          : "''${PANEL_BASE:=/}"
          : "''${PANEL_TOKEN:?PANEL_TOKEN is required}"

          BASE="''${PANEL_BASE%/}"
          URL="''${PANEL_URL%/}''${BASE}/panel/api/server/restartXrayService"

          echo "[reconfig] POST $URL" >&2
          RESPONSE="$(curl -sS --max-time 60 -k \
            -H "Authorization: Bearer $PANEL_TOKEN" \
            -X POST "$URL")"

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
  };
}
