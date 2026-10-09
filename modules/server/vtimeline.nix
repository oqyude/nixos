{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:

# Veeam Timeline View — static frontend + REST API, both served by a
# single Node.js/Express process. nginx reverse-proxies the entire
# vtimeline.zeroq.su vhost to the local listener (see the vhost in
# modules/server/nginx.nix — no `root`, no `try_files`).
#
# API surface (server.js):
#   GET    /api/uploads         list uploaded JSONs
#   POST   /api/uploads         upload (raw JSON or {name, content}, ≤ 5 MB)
#   GET    /api/uploads/:name   fetch parsed
#   DELETE /api/uploads/:name   delete
#
# Auth: delegated to Authelia at the nginx layer (`auth_request
# /authelia` on the vhost). The API itself trusts whoever reaches it —
# the only ingress is the same-origin nginx proxy, so the wide-open
# CORS header in server.js is a no-op in practice.
#
# Storage: /home/oqyude/External/Git/VeeamTimelineView/
#   ├── public_html/   static frontend (read-only at runtime)
#   ├── server.js      Express app
#   ├── node_modules/  installed deps (express + transitive)
#   └── uploads/       persistent JSON uploads (read+write)
#
# The repo lives on the External ext4 drive (fstab). The service gates
# on home-oqyude-External.mount so it never starts against an empty
# directory after a cold boot without the drive plugged in.
let
  user = xlib.device.username;
  group = "users";
  repo = "/home/oqyude/External/Git/VeeamTimelineView";
  port = 8000;
  node = pkgs.nodejs_22;
in
{
  # systemPackages so /run/current-system/sw/bin/node exists for any
  # operator tooling (logs, ad-hoc npm scripts). The systemd unit
  # below references the absolute Nix-store path, so this is purely
  # for the CLI path.
  environment.systemPackages = [ node ];

  # Bind-mount public_html into /var/lib. The current vhost proxies
  # all traffic to the node listener, so nginx itself does not need
  # this — kept for parity with the pre-API setup (so any future
  # static-only fallback or external inspection has a stable
  # /home-independent path). x-systemd.automount + nofail: a missing
  # /home/oqyude/External only surfaces as a per-request 404, never a
  # boot failure.
  systemd.mounts = [
    (xlib.helpers.mkSystemdBind {
      what = "${repo}/public_html";
      where = "/var/lib/vtimeline";
    })
  ];
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/var/lib/vtimeline" "0755" "nginx" "nginx")
  ];

  systemd.services.vtimeline-api = {
    description = "Veeam Timeline View API (Node.js + Express)";
    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "home-oqyude-External.mount"
    ];
    wants = [ "network-online.target" ];
    requires = [ "home-oqyude-External.mount" ];

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = group;
      WorkingDirectory = repo;
      ExecStart = "${node}/bin/node ${repo}/server.js";
      Environment = "PORT=${toString port}";

      Restart = "on-failure";
      RestartSec = "5s";

      # Sandbox. Server.js only needs to read public_html/ +
      # node_modules/ and to read-write uploads/. ReadWritePaths
      # lifts the ProtectHome/ProtectSystem write protection for
      # uploads/ only; everywhere else stays read-only.
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [ "${repo}/uploads" ];
    };
  };
}
