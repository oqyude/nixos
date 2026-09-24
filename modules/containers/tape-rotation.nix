{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# TapeRotation — web app for tracking and rotation of backup tape
# cartridges. https://github.com/ElizarovEugene/TapeRotation
#
# Podman adaptation of the upstream docker-compose deployment. Two
# containers on a shared "taperotation_default" network (mirrors the
# compose project network):
#   - taperotation-backend:  FastAPI/uvicorn on :8001, SQLite at /data,
#                            file attachments at /app/uploads
#   - taperotation-frontend: nginx serving the built React app on :80,
#                            proxying /api to http://backend:8001
# The backend container gets a static IP on the shared network and the
# frontend maps "backend" → that IP via --add-host, because this host's
# CoreDNS service owns port 53 on every interface: the podman network DNS
# plugin (aardvark-dns) cannot bind on the network gateway, so a network
# with dns_enabled would refuse to attach containers.
#
# Published host port 5174 → container:80 for the web UI. Keep it out
# of networking.firewall like the other panel ports and front it with an
# nginx vhost, e.g. in server/nginx.nix:
#   { domain = "tape-rotation.zeroq.su"; port = 5174; }
# and set APP_URL / CORS_ORIGINS in the sops-encrypted env file.
#
# Instance config lives in one sops-encrypted .env file (mirrors the
# upstream .env.example, sops-nix format = "dotenv", key = "" → whole
# file):  sops modules/containers/secrets/tape-rotation.env
# On first boot the admin account is created from ADMIN_USERNAME /
# ADMIN_PASSWORD from that file.
let
  panel = "${xlib.dirs.services-nodes-folder}/${xlib.device.hostname}/tape-rotation";
in
{
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
      containers = {
        "taperotation-backend" = {
          image = "docker.io/elizaroveugene/taperotation-backend:latest";
          environment = {
            "DATABASE_URL" = "sqlite:////data/taperotation.db";
            "JWT_EXPIRE_MINUTES" = "480";
            "ADMIN_USERNAME" = "admin";
            "ADMIN_LANGUAGE" = "en";
            "NOTIFY_DAYS_BEFORE" = "7";
            "TZ" = "Europe/Moscow";
          };
          environmentFiles = [ "/run/secrets/tape-rotation-env" ];
          volumes = [
            "${panel}/db:/data:rw"
            "${panel}/uploads:/app/uploads:rw"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=taperotation_default"
            # Static IP the frontend reaches "backend" at (see --add-host
            # in the frontend container; network DNS is disabled).
            "--ip=10.89.0.10"
          ];
        };
        "taperotation-frontend" = {
          image = "docker.io/elizaroveugene/taperotation-frontend:latest";
          ports = [
            "0.0.0.0:5174:80/tcp"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=taperotation_default"
            # Baked-in nginx upstream is http://backend:8001; resolve it via
            # /etc/hosts since the network has no DNS plugin.
            "--add-host=backend:10.89.0.10"
          ];
        };
      };
    };
  };

  # Enable container name DNS for all Podman networks.
  networking.firewall.interfaces =
    let
      matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
    in
    {
      "${matchAll}".allowedUDPPorts = [ 53 ];
    };

  systemd = {
    services = {
      "podman-taperotation-backend" = {
        serviceConfig.Restart = lib.mkOverride 90 "always";
        after = [ "podman-network-taperotation_default.service" ];
        requires = [ "podman-network-taperotation_default.service" ];
        partOf = [ "podman-compose-tape-rotation-root.target" ];
        wantedBy = [ "podman-compose-tape-rotation-root.target" ];
      };
      "podman-taperotation-frontend" = {
        serviceConfig.Restart = lib.mkOverride 90 "always";
        after = [
          "podman-network-taperotation_default.service"
          "podman-taperotation-backend.service"
        ];
        requires = [ "podman-network-taperotation_default.service" ];
        partOf = [ "podman-compose-tape-rotation-root.target" ];
        wantedBy = [ "podman-compose-tape-rotation-root.target" ];
      };
      "podman-network-taperotation_default" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f taperotation_default";
        };
        script = ''
          # Always (re)create the stack network: the host's CoreDNS owns :53
          # on every interface, so the network DNS plugin (aardvark-dns)
          # can't bind on the gateway → --disable-dns. --subnet backs the
          # backend's static IP. Recreate-on-start also self-heals after a
          # `podman system prune` removed the (temporarily unused) network.
          podman network rm -f taperotation_default >/dev/null 2>&1 || true
          podman network create --disable-dns --subnet=10.89.0.0/24 taperotation_default
        '';
        partOf = [ "podman-compose-tape-rotation-root.target" ];
        wantedBy = [ "podman-compose-tape-rotation-root.target" ];
      };
      "podman-update-taperotation" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutSec = 300;
        };
        script = ''
          podman pull docker.io/elizaroveugene/taperotation-backend:latest
          podman pull docker.io/elizaroveugene/taperotation-frontend:latest
          systemctl restart podman-taperotation-backend.service podman-taperotation-frontend.service
        '';
      };
    };
    # Starts/stops together with all TapeRotation containers.
    targets."podman-compose-tape-rotation-root" = {
      unitConfig.Description = "Root target generated by compose2nix.";
      wantedBy = [ "multi-user.target" ];
    };
    # Enable automatic image updates:
    # systemd.timers."podman-update-taperotation" = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "weekly";
    #     Persistent = true;
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
      (xlib.helpers.mkTmpfile "d" "${panel}/uploads" "0755" "root" "root")
      # Relabel panel dir for SELinux so containers can access it.
      (xlib.helpers.mkTmpfile "Z" panel "0755" "root" "root")
    ];
  };

  sops.secrets."tape-rotation-env" = {
    # key = "" → decrypt the whole file, not a single key.
    # format = "dotenv" → the file IS one .env ready for environmentFiles:
    # every non-comment KEY=VALUE line lands in the container environment.
    key = "";
    format = "dotenv";
    sopsFile = ./secrets/tape-rotation.env;
    mode = "0400";
  };
}
