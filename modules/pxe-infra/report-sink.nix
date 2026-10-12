# pxe-infra/report-sink — minimal HTTP service that accepts
# run reports from the L4 VM and stores them on disk.
#
# Per docs/ARCHITECTURE.md §L6, the report sink must survive
# the VM's disappearance. The VM pushes (over HTTP to the
# bridge IP) and this service writes the report under
# /var/lib/pxe-infra/reports/, which is the only on-host
# location a report is guaranteed to land.
#
# Design notes:
#   - Python stdlib only — no extra dependency, no version
#     drift, no additional security surface. The script lives
#     in ./report-sink.py, read at eval time.
#   - DynamicUser + StateDirectory: the daemon runs as a
#     throwaway UID with write access to
#     /var/lib/pxe-infra/reports. No persistent system-user
#     state to maintain.
#   - Hardening: ProtectSystem=strict, NoNewPrivileges,
#     PrivateTmp, RestrictAddressFamilies. We only need to
#     bind a TCP socket and write a file; everything else is
#     denied.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  script = pkgs.writeText "report-sink.py" (builtins.readFile ./report-sink.py);
in
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.reportSink.enable) {
    systemd.services.pxe-infra-report-sink = {
      description = "pxe-infra: report sink (L6)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
        StateDirectory = "pxe-infra/reports";
        # Bind to the bridge IP only — never 0.0.0.0.
        Environment = [
          "REPORTS_BIND=${config.pxe-infra.bridge.address}"
          "REPORTS_PORT=${toString config.pxe-infra.reportSink.port}"
          "REPORTS_DIR=/var/lib/pxe-infra/reports"
          "PYTHONUNBUFFERED=1"
        ];
        # Hardening.
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        ReadWritePaths = [ "/var/lib/pxe-infra" ];
      };

      script = ''
        exec ${pkgs.python3}/bin/python3 ${script}
      '';
    };
  };
}
