{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# Open WebUI — self-hosted AI chat UI, deployed here as a UI-client for
# external LLM APIs (OpenAI-compatible: OpenAI, OpenRouter, vLLM, LM Studio,
# GroqCloud, Mistral, etc.). Runs locally without bundled Ollama.
#
# Architecture mirrors modules/containers/{3x-ui,tape-rotation}.nix:
#   - one container, one systemd unit + a root.target
#   - data on /mnt/services/nodes/<host>/open-webui/data → /app/backend/data
#     (see AGENTS.md §Подтверждённые инварианты #2 — guard chain is satisfied
#     because mkServiceStorage already bind-mounts /mnt/services on boot)
#   - host port bound to 127.0.0.1 only — the only ingress is the nginx
#     vhost open.zeroq.su (no firewall exception, no public exposure).
#     Same pattern as 3x-ui.nix:30-31 binding the panel to 127.0.0.1:2049.
#
# Secrets come from a single sops-encrypted dotenv file
# (format = "dotenv", key = "" → whole file). The owner creates the
# encrypted file with `sops modules/containers/secrets/open-webui.env`
# after filling the .example template next to it.
#
# Hard requirement (env.py:762 — SystemExit at startup):
#   WEBUI_SECRET_KEY must be set when WEBUI_AUTH=true.
#   Generate with:  head -c 24 /dev/urandom | base64
#
# Reverse-proxy requirements (docs.openwebui.com/reference/https):
#   - WEBUI_URL    = public HTTPS URL (OAuth callbacks, internal links)
#   - CORS_ALLOW_ORIGIN = same public URL (else WebSocket fails silently)
#   - proxy_buffering off    (else SSE streaming breaks markdown)
#   - proxy_read_timeout ≥ 300s (LLM responses can run minutes)
#   - WebSocket pass-through (Upgrade / Connection headers)
# All of the above are wired into modules/server/nginx.nix:open.zeroq.su.
let
  panel = "${xlib.dirs.services-nodes-folder}/${xlib.device.hostname}/open-webui";
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
      containers."open-webui" = {
        image = "ghcr.io/open-webui/open-webui:main";
        environment = {
          TZ = "Europe/Moscow";
          # Container-internal port (also the upstream default).
          PORT = "8080";
          # Required when behind a public HTTPS URL — OAuth callbacks,
          # share links and internal redirects resolve against this.
          WEBUI_URL = "https://open.zeroq.su";
          # Must exactly match WEBUI_URL or WebSocket connections fail
          # silently (per upstream HTTPS docs). nginx (127.0.0.1) is the
          # only allowed origin, so a single explicit URL is enough.
          CORS_ALLOW_ORIGIN = "https://open.zeroq.su";
          # Honour X-Forwarded-* headers from the reverse proxy.
          FORWARDED_ALLOW_IPS = "127.0.0.1";
          # Closed self-hosted: admin creates accounts manually after the
          # first boot via WEBUI_ADMIN_* from the sops env file.
          WEBUI_AUTH = "True";
          ENABLE_SIGNUP = "False";
          ENABLE_LOGIN_FORM = "True";
          ENABLE_VERSION_UPDATE_CHECK = "False";
          # Out of the box Open WebUI phones home to Scarf. The opt-outs
          # below preserve the previous behaviour from the stub at
          # modules/server/open-webui.nix (still in tree, commented out in
          # modules/server/default.nix:41) until that file is removed.
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          # No bundled providers. Owners wire OPENAI_API_KEY /
          # OPENAI_API_BASE_URL / etc. either via the sops env file
          # (see sops.secrets."open-webui-env" below) or interactively in
          # Admin → Settings → Connections once WEBUI_AUTH=true. Empty
          # base URL is intentional: an empty OPENAI_API_BASE_URL
          # disables the default /ollama proxy and prevents the container
          # from probing localhost:11434 on boot.
          OLLAMA_BASE_URL = "";
          OPENAI_API_BASE_URL = "";
        };
        # Mount the decrypted dotenv only when the sops file exists. Until
        # the owner creates ./secrets/open-webui.env, the inline environment
        # is the only source — and the container will refuse to start with
        # WEBUI_SECRET_KEY="" (env.py:762 — SystemExit). The error message is
        # the clear signal that the secret needs to be created.
        environmentFiles = lib.optional (builtins.pathExists ./secrets/open-webui.env)
          "/run/secrets/open-webui-env";
        volumes = [
          "${panel}/data:/app/backend/data:rw"
        ];
        log-driver = "journald";
        # 127.0.0.1 only — the container is not exposed externally.
        ports = [ "127.0.0.1:8080:8080/tcp" ];
      };
    };
  };

  # Enable container name DNS for all Podman networks (mirrors 3x-ui.nix:120-128).
  networking.firewall.interfaces =
    let
      matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
    in
    {
      "${matchAll}".allowedUDPPorts = [ 53 ];
    };

  systemd = {
    services = {
      "podman-open-webui" = {
        serviceConfig.Restart = lib.mkOverride 90 "always";
        partOf = [ "podman-compose-open-webui-root.target" ];
        wantedBy = [ "podman-compose-open-webui-root.target" ];
      };
      "podman-update-open-webui" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutSec = 300;
        };
        script = ''
          podman pull ghcr.io/open-webui/open-webui:main
          systemctl restart podman-open-webui.service
        '';
      };
    };
    # Starts/stops together with the open-webui container.
    targets."podman-compose-open-webui-root" = {
      unitConfig.Description = "Root target for open-webui.";
      wantedBy = [ "multi-user.target" ];
    };
    # Enable automatic image updates:
    # systemd.timers."podman-update-open-webui" = {
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
      (xlib.helpers.mkTmpfile "d" "${panel}/data" "0755" "root" "root")
      # Relabel panel dir for SELinux so containers can access it.
      (xlib.helpers.mkTmpfile "Z" panel "0755" "root" "root")
    ];
  };

  # sops secret is declared only when the encrypted file actually exists,
  # so the flake still evaluates (and rebuilds apply) on a host that hasn't
  # created the secret yet. Once ./secrets/open-webui.env is created and
  # encrypted with `sops modules/containers/secrets/open-webui.env`, this
  # condition becomes true and the secret is wired in.
  #
  # Hard requirement (env.py:762 — SystemExit at startup):
  # WEBUI_SECRET_KEY must be present in the env file when WEBUI_AUTH=true.
  sops.secrets = lib.optionalAttrs (builtins.pathExists ./secrets/open-webui.env) {
    "open-webui-env" = {
      # key = "" → decrypt the whole file, not a single key.
      # format = "dotenv" → the file IS one .env ready for environmentFiles:
      # every non-comment KEY=VALUE line lands in the container environment.
      # After this module is wired the file is mounted at
      # /run/secrets/open-webui-env (sops-nix default for this attr name).
      key = "";
      format = "dotenv";
      sopsFile = ./secrets/open-webui.env;
      mode = "0400";
    };
  };
}