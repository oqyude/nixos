{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  panel = "${xlib.dirs.services-nodes-folder}/${xlib.device.hostname}/3x-ui";
  # Domain whose Let's Encrypt cert (at /var/lib/acme/<domain>/) gets mounted
  # read-only into the 3x-ui container so the panel can terminate TLS itself.
  # Null when 3x-ui serves plain HTTP and TLS is terminated by an upstream
  # nginx.
  certDomain = config.host."3x-ui".certDomain;
  certMounts =
    if certDomain == null then
      [ ]
    else
      # LE cert mounted read-only so 3x-ui can terminate TLS itself.
      # The 3x-ui settings table must point webCertFile / webKeyFile at
      # /root/cert/fullchain.pem and /root/cert/key.pem.
      map (f: "/var/lib/acme/${certDomain}/${f}:/root/cert/${f}:ro") [
        "fullchain.pem"
        "key.pem"
      ];
  basePorts = [
    # 3x-ui panel + subscription endpoint on the loopback only.
    "127.0.0.1:2049:2049/tcp"
    "127.0.0.1:2096:2096/tcp"
    # xray's Reality inbound on the loopback only — nginx stream (in
    # modules/server/nginx.nix) listens on the public 8443 and forwards
    # here. Going nginx-stream → podman → xray keeps Reality's TLS
    # ClientHello intact end-to-end; exposing 8443 directly via podman
    # port-forward mangles it and clients see the fallback cert.
    "127.0.0.1:15380:8443/tcp"
  ];
  # VDS-only: nginx stream forwards host:443 → 127.0.0.1:15380 →
  # container:443, so Xray sees its REALITY inbound on port 443.
  realityPorts = lib.optional config.host."3x-ui".reality443Forwarding "127.0.0.1:15380:443/tcp";
  # Workaround for a 3x-ui panel bug (both 3.8.5 and 3.9.0 reproduce it): when
  # generating bin/config.json from the inbounds DB rows, the panel drops the
  # inner `realitySettings.settings.{publicKey,fingerprint,serverName,spiderX,
  # mldsa65Verify}` block — without which the xray Reality server cannot
  # complete the auth handshake with any client. The DB has the data; only
  # the generated config.json is missing it. This script reads DB inside the
  # running container and re-applies the missing fields to bin/config.json,
  # then SIGHUPs xray so clients can connect. Runs every 30s; safe to
  # overlap with the panel's own config writes (it's idempotent and only
  # touches missing/different fields).
  #
  # Both migrateScript (one-shot at container start) and patchScript +
  # timer (every 10s) are commented out as of 2026-10-04: the user is
  # switching the xray-core version through the panel UI instead of
  # patching config.json from NixOS. See ./3x-ui-migration-notes.md for
  # the full investigation, the panel bug reference, and how to re-enable
  # the workarounds if a future panel build re-introduces the issue.
  #
  # REAL ROOT-CAUSE FIX for the 3x-ui config-gen bug.
  #
  # In `internal/web/service/xray.go` the panel's `GetXrayConfig()`
  # function does this on every config regeneration (xray restart, inbound
  # update, restartXrayService API call):
  #
  #     realitySettings, ok2 := stream["realitySettings"].(map[string]any)
  #     if ok2 { delete(realitySettings, "settings") }
  #
  # i.e. it explicitly drops the *nested* `realitySettings.settings` block
  # before serialising to bin/config.json. The panel's inbound DB row
  # stores these fields under `stream_settings.realitySettings.settings`,
  # so every regeneration wipes publicKey/fingerprint/serverName/spiderX/
  # mldsa65Verify from the live xray config, breaking Reality-auth for
  # every inbound.
  #
  # The proper fix is to move these fields from the nested `settings` block
  # to the *top level* of `realitySettings` directly in the DB. Panel's
  # delete() targets the nested block only; top-level fields pass through
  # untouched, and Panel passes them through to bin/config.json correctly.
  #
  # The migration is idempotent (no-op once fields are top-level) and is
  # re-applied on every container start so that any new inbound created
  # via the panel UI gets migrated automatically.
  #
  # migrateScript = pkgs.writeScript "migrate-3xui-reality.py" ''
  #   #!/usr/bin/env python3
  #   """Move Reality fields from nested settings to top-level realitySettings in DB.
  #
  #   Idempotent. Re-applied on every container start so newly-added inbounds
  #   are auto-migrated."""
  #   import json, sqlite3, sys
  #   FIELDS = ("publicKey", "fingerprint", "serverName", "spiderX", "mldsa65Verify")
  #   try:
  #       conn = sqlite3.connect("/etc/x-ui/x-ui.db")
  #       rows = conn.execute(
  #           "SELECT id, stream_settings FROM inbounds "
  #           "WHERE stream_settings IS NOT NULL AND protocol='vless'"
  #       ).fetchall()
  #       migrated = 0
  #       for rid, ss_json in rows:
  #           ss = json.loads(ss_json)
  #           rs = ss.get("realitySettings")
  #           if not rs:
  #               continue
  #           inner = rs.get("settings", {})
  #           if not inner:
  #               continue
  #           changed = False
  #           for k in FIELDS:
  #               v = inner.get(k)
  #               if v and not rs.get(k):
  #                   rs[k] = v
  #                   changed = True
  #           if changed:
  #               conn.execute(
  #                   "UPDATE inbounds SET stream_settings=? WHERE id=?",
  #                   (json.dumps(ss), rid),
  #               )
  #               migrated += 1
  #       conn.commit()
  #       conn.close()
  #       print(f"migrated={migrated}")
  #   except Exception as e:
  #       print(f"ERROR: {e}", file=sys.stderr)
  #       sys.exit(1)
  # '';
  # Patches /app/bin/config.json inside the running container so every reality
  # inbound has top-level publicKey/fingerprint/serverName/spiderX/mldsa65Verify
  # sourced from the panel's DB. The 3x-ui panel's GetXrayConfig (in
  # internal/web/service/xray.go) explicitly drops the nested
  # `realitySettings.settings` block before serialising bin/config.json
  # (a bug in v3.8.5 and v3.9.0). After every panel regeneration (xray
  # restart, inbound update, restartXray API call) xray is left without the
  # public fields and REALITY auth fails for every inbound. Re-running the
  # DB-only migration at container start is not enough: the panel overwrites
  # stream_settings back to nested-only within seconds for active inbounds.
  # We re-read the source-of-truth nested block from /etc/x-ui/x-ui.db and
  # re-inject the missing top-level fields into the rendered config.json,
  # then SIGHUP xray so it picks up the patch without dropping live
  # connections. Idempotent. Runs every 10s via systemd timer; the
  # migrateScript service covers first boot.
  #
  # patchScript = pkgs.writeScript "patch-3xui-xray-config.py" ''
  #   #!/usr/bin/env python3
  #   """Patch /app/bin/config.json so every reality inbound has the public fields
  #   xray needs to complete the REALITY handshake. Idempotent: no-op once
  #   top-level fields are present."""
  #   import json, os, signal, sqlite3, sys
  #   CFG = "/app/bin/config.json"
  #   FIELDS = ("publicKey", "fingerprint", "serverName", "spiderX", "mldsa65Verify")
  #   try:
  #       conn = sqlite3.connect("/etc/x-ui/x-ui.db")
  #       rows = conn.execute(
  #           "SELECT id, port, stream_settings FROM inbounds "
  #           "WHERE stream_settings IS NOT NULL AND protocol='vless'"
  #       ).fetchall()
  #       port_to_src = {}
  #       for _, port, ss_json in rows:
  #           ss = json.loads(ss_json)
  #           rs = ss.get("realitySettings") or {}
  #           inner = rs.get("settings") or {}
  #           src = {k: v for k in FIELDS if (v := rs.get(k) or inner.get(k))}
  #           if src:
  #               port_to_src[port] = src
  #       conn.close()
  #       if not port_to_src:
  #           print("no-source")
  #           sys.exit(0)
  #       with open(CFG) as f:
  #           cfg = json.load(f)
  #       patched = []
  #       for ib in cfg.get("inbounds", []):
  #           port = ib.get("port")
  #           src = port_to_src.get(port)
  #           if not src:
  #               continue
  #           ss = ib.setdefault("streamSettings", {})
  #           rs = ss.setdefault("realitySettings", {})
  #           ib_changed = False
  #           for k, v in src.items():
  #               if rs.get(k) != v:
  #                   rs[k] = v
  #                   ib_changed = True
  #           if ib_changed:
  #               patched.append(port)
  #       if not patched:
  #           print("clean")
  #           sys.exit(0)
  #       tmp = CFG + ".tmp"
  #       with open(tmp, "w") as f:
  #           json.dump(cfg, f, indent=2)
  #       os.replace(tmp, CFG)
  #       sent = 0
  #       for entry in os.listdir("/proc"):
  #           if not entry.isdigit():
  #               continue
  #           try:
  #               with open(f"/proc/{entry}/comm") as f:
  #                   comm = f.read().strip()
  #               if comm.startswith("xray"):
  #                   os.kill(int(entry), signal.SIGHUP)
  #                   sent += 1
  #           except (FileNotFoundError, ProcessLookupError, ValueError):
  #               continue
  #       print(f"patched ports={patched} sighup={sent}")
  #   except Exception as e:
  #       print(f"ERROR: {e}", file=sys.stderr)
  #       sys.exit(1)
  # '';
in
{
  # `host."3x-ui"` options are declared in modules/options.nix: they are set
  # by modules/server and modules/vds, so this module cannot be the only place
  # that knows they exist.
  config = {
    virtualisation = {
      podman = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
        };
        dockerCompat = true;
      };
      oci-containers = {
        backend = "podman";
containers."3xui_app" = {
          # Pinned to v3.9.0 (latest stable at 2026-10-03) as of the 2026-10-04
          # clean regress. The xray-core version is no longer managed here —
          # it is switched through the panel UI (Settings → Xray version),
          # which writes to /app/bin/xray-linux-amd64 inside the container.
          # The migrateScript + patchScript + service + timer workarounds for
          # the panel's GetXrayConfig bug are commented out in this file;
          # see ./3x-ui-migration-notes.md for the full investigation and
          # how to re-enable them if a future panel build reintroduces the
          # issue.
          image = "ghcr.io/mhsanaei/3x-ui:v3.9.0";
          environment = {
            "XRAY_VMESS_AEAD_FORCED" = "false";
            "XUI_ENABLE_FAIL2BAN" = "true";
            "TZ" = "Europe/Moscow";
          };
          volumes = [
            "${panel}/cert/:/root/cert:rw"
            "${panel}/db/:/etc/x-ui:rw"
          ]
          ++ certMounts;
          log-driver = "journald";
          # Adding a new inbound through the 3x-ui panel on a port outside
          # the 14380-15379 range requires extending basePorts and rebuilding.
          ports = basePorts ++ realityPorts;
        };
      };
    };

    systemd = {
      services = {
        "podman-3xui_app" = {
          serviceConfig.Restart = lib.mkOverride 90 "always";
          partOf = [ "podman-compose-3x-ui-root.target" ];
          wantedBy = [ "podman-compose-3x-ui-root.target" ];
        };
        "podman-update-3xui_app" = {
          path = [ pkgs.podman ];
          serviceConfig = {
            Type = "oneshot";
            TimeoutSec = 300;
          };
          script = ''
            podman pull ghcr.io/mhsanaei/3x-ui:v3.8.5
            systemctl restart podman-3xui_app.service
          '';
        };
        # Real fix for the panel config-gen bug: run the DB migration once
        # after each container start so any new inbounds (created via panel UI
        # or API) have their Reality public fields moved to top-level on the
        # next launch. The migration is idempotent — a no-op once fields are
        # top-level — so it's safe to run on every container start.
        #
        # The script is piped into the container via stdin rather than
        # referenced by its host-side /nix/store path (which does not exist
        # inside the container). Restart=on-failure so a transient container
        # race (e.g. 3x-ui still seeding the DB on first start) is retried
        # instead of silently passing.
        #
        # COMMENTED OUT 2026-10-04 — user switched to changing the xray-core
        # version through the panel UI instead of patching config.json from
        # NixOS. See ./3x-ui-migration-notes.md. To re-enable, uncomment
        # this service AND the corresponding migrateScript in the `let`
        # block above.
        #
        # "migrate-3xui-reality" = {
        #   path = [ pkgs.podman ];
        #   serviceConfig = {
        #     Type = "oneshot";
        #     RemainAfterExit = true;
        #     Restart = "on-failure";
        #     RestartSec = 5;
        #   };
        #   script = ''
        #     ${pkgs.podman}/bin/podman exec -i 3xui_app python3 < ${migrateScript}
        #   '';
        #   after = [ "podman-3xui_app.service" ];
        #   wantedBy = [ "podman-compose-3x-ui-root.target" ];
        # };
        # Continuous patch: every 10s the timer re-injects the public
        # reality fields into /app/bin/config.json and SIGHUPs xray so the
        # panel's GetXrayConfig bug cannot keep auth broken for more than
        # one timer interval. The migrate-3xui-reality service above only
        # covers first boot; the panel overwrites stream_settings back to
        # nested-only within seconds, so a oneshot at container start is
        # not enough.
        #
        # COMMENTED OUT 2026-10-04 — same reason as migrate-3xui-reality
        # above. Uncomment this service, the corresponding patchScript in
        # the `let` block, and the timer below to re-enable the per-10s
        # patch loop. See ./3x-ui-migration-notes.md.
        #
        # "patch-3xui-xray-config" = {
        #   path = [ pkgs.podman ];
        #   serviceConfig = {
        #     Type = "oneshot";
        #     TimeoutSec = 30;
        #   };
        #   script = ''
        #     ${pkgs.podman}/bin/podman exec -i 3xui_app python3 < ${patchScript}
        #   '';
        # };
      };
      # Starts/stops together with all 3x-ui compose resources.
      targets."podman-compose-3x-ui-root" = {
        unitConfig.Description = "Root target generated by compose2nix.";
        wantedBy = [ "multi-user.target" ];
      };
      # COMMENTED OUT 2026-10-04 — see ./3x-ui-migration-notes.md and the
      # commented-out patch-3xui-xray-config service above. Uncomment to
      # re-enable the per-10s config.json patch loop.
      #
      # timers."patch-3xui-xray-config" = {
      #   wantedBy = [ "timers.target" ];
      #   timerConfig = {
      #     OnBootSec = "20s";
      #     OnUnitActiveSec = "10s";
      #     Persistent = false;
      #     Unit = "patch-3xui-xray-config.service";
      #   };
      # };
      tmpfiles.rules = [
        (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
        (xlib.helpers.mkTmpfile "d" xlib.dirs.services-nodes-folder "0755" "root" "root")
        (xlib.helpers.mkTmpfile "d" "${xlib.dirs.services-nodes-folder}/${xlib.device.hostname}" "0755"
          "root"
          "root"
        )
        (xlib.helpers.mkTmpfile "d" panel "0755" "root" "root")
        (xlib.helpers.mkTmpfile "d" "${panel}/db" "0755" "root" "root")
        (xlib.helpers.mkTmpfile "d" "${panel}/cert" "0755" "root" "root")
        # Relabel panel dir for SELinux so containers can access it.
        (xlib.helpers.mkTmpfile "Z" panel "0755" "root" "root")
      ];
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall = {
      interfaces =
        let
          matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
        in
        {
          "${matchAll}".allowedUDPPorts = [ 53 ];
        };
    };
  };
}
