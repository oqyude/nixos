{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  serviceName = "rsync-services-sync";
  serverAddress = "oqyude@100.64.0.0";
  serverDir = "${xlib.dirs.services-nodes-folder}/${xlib.device.hostname}";
  nodeDir = "${xlib.dirs.services-mnt-folder}";
in
{
  systemd = {
    services = {
      "${serviceName}" = {
        description = "Bidirectional rsync";
        unitConfig.RequiresMountsFor = [ ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # Только по таймеру: НЕ блокируем boot и активацию nixos-rebuild.
        script = ''
          set -euo pipefail

          RSYNC="${pkgs.rsync}/bin/rsync"
          SSH="${pkgs.openssh}/bin/ssh"

          SSH_CMD="$SSH \
            -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -o ServerAliveInterval=5 \
            -o ServerAliveCountMax=3 \
            -o StrictHostKeyChecking=no"

          mkdir -p "${nodeDir}"

          # best-effort: сервер недоступен -> выходим сразу, никаких циклов ожидания
          if ! $SSH_CMD ${serverAddress} true >/dev/null 2>&1; then
            echo "Server ${serverAddress} unreachable, skipping sync"
            exit 0
          fi

          if [ ! -d "${nodeDir}" ] || [ -z "$(ls -A "${nodeDir}")" ]; then
            echo "Pull <- ${serverAddress}"

            $RSYNC \
              -e "$SSH_CMD" \
              -a \
              "${serverAddress}:${serverDir}/" \
              "${nodeDir}/"
          else
            echo "Push -> ${serverAddress}"

            $RSYNC \
              -e "$SSH_CMD" \
              -a \
              --delete \
              "${nodeDir}/" \
              "${serverAddress}:${serverDir}/"
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          Nice = 10;
          CPUQuota = "5%";
          IOSchedulingClass = "idle";
          # страховка от зависшего rsync/ssh; легитимная большая синхронизация
          # укладывается в это окно (на фоне idle-приоритета)
          TimeoutStartSec = 600;
        };
      };
    };
    timers = {
      "${serviceName}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "${serviceName}.service";
        };
      };
    };
  };
}
