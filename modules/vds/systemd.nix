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
  serverDir = "/mnt/services/nodes/vds";
  nodeDir = "/mnt/services";
in
{
  systemd = {
    services = {
      "${serviceName}" = {
        description = "Bidirectional rsync";
        unitConfig.RequiresMountsFor = [ ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        script = ''
          set -euo pipefail

          RSYNC="${pkgs.rsync}/bin/rsync"
          SSH="${pkgs.openssh}/bin/ssh"

          SSH_CMD="$SSH \
            -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -o StrictHostKeyChecking=no"

          echo "Waiting for server..."

          for i in $(seq 1 60); do
            echo "Attempt $i"

            if $SSH_CMD ${serverAddress} true >/dev/null 2>&1; then
              echo "Server available"
              break
            fi

            sleep 5
          done

          # final check
          $SSH_CMD ${serverAddress} true >/dev/null 2>&1

          mkdir -p "${nodeDir}"

          if [ ! -d "${nodeDir}" ] || [ -z "$(ls -A "${nodeDir}")" ]; then
            echo "Pull <- ${serverAddress}"

            mkdir -p "${nodeDir}"

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
