# Declarative OpenCode v2 + oh-my-opencode-slim setup.
#
# HISTORY / WHY THIS FILE LOOKS LIKE THIS
#
# 2026-10-20: sapphira migrated from OpenCode 1.19.0 (v1) to OpenCode 2.0.32
# (v2). See ADR-0006. The v1 -> v2 deltas that matter here:
#
#   * package     — v2 is NOT in nixos-unstable yet (that still ships 1.19.0).
#                   It landed in nixpkgs master (PR #569770, merged 2026-10-19),
#                   so the binary comes from the `nixpkgs-master` input that was
#                   already wired into this flake. `nix flake update
#                   nixpkgs-master` is what moves the pin onto a rev that has
#                   v2 — the lock must be updated together with this file.
#   * config keys — v1: `plugin` (singular) + `mcp` (flat map).
#                   v2: `plugins` (plural) + `mcp.servers` (nested).
#   * tui.json    — v1 wrote CLI/TUI prefs to `tui.json`; v2 reads them from
#                   `cli.json` ($schema https://opencode.ai/v2/cli.json) and
#                   only *migrates* tui.json -> cli.json on first run. On
#                   sapphira `tui.json` is a symlink into /nix/store (read-only),
#                   so the migration cannot write: `cli.json` is declared
#                   explicitly below and `programs.opencode.tui` stays empty.
#   * port        — v1 `opencode serve` defaulted to 4096; v2 defaults to 4097
#                   (4096 is reserved for the v2 background service). The nginx
#                   vhost `opencode.zeroq.su` proxies to 127.0.0.1:4096, so
#                   `--port 4096` is pinned explicitly in `web.extraArgs`.
#                   Without it the proxy silently 502s.
#   * `opencode web` is gone in v2; `opencode serve` serves both the API and
#                   the web UI (verified locally: GET / -> 200 HTML,
#                   GET /api/health without creds -> 401 UnauthorizedError).
#   * auth        — unchanged: OPENCODE_PASSWORD, falling back to
#                   OPENCODE_SERVER_PASSWORD (sops: secrets/opencode.env ->
#                   ~/.config/opencode/server.env). HTTP basic, user `opencode`.
#   * plugins     — v2 installs npm plugin packages itself (in-process
#                   arborist, no bun/npx needed) into ~/.cache/opencode/npm/.
#                   Only `oh-my-opencode-slim` is v2-ready: it ships
#                   dist/tui2.js + dist/v2/tui.d.ts and documents an
#                   "OpenCode v2 compatibility" matrix. The pre-v2 plugin
#                   (5.1.40) exports only ./tui + ./server and has no v2
#                   entry point, so it is NOT installed and NOT enabled
#                   under v2 (see ADR-0006).
#
# Files this module owns on disk:
#   ~/.config/opencode/opencode.json           <- programs.opencode.settings
#   ~/.config/opencode/cli.json                 <- v2 CLI/TUI preferences
#   ~/.config/opencode/oh-my-opencode-slim.json <- slim plugin config; the
#                                                   ONLY plugin config
#   ~/.config/opencode/service.json             <- v2 background service (off)
#
# The legacy v1 plugin config (its home-dir config + the mirror under
# ~/.config/opencode/) was REMOVED 2026-10-25: it was inert under v2 and
# only kept alive a "switch back to openagent" path that does not exist.
# History and reasoning: ADR-0006.
#
# Imported by home/server.nix (sapphira). Auto-enables programs.opencode.
{
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  # OpenCode v2 only exists in nixpkgs master for now. Import it the same way
  # modules/server/nextcloud.nix already imports `nixpkgs-master`.
  masterPkgs = import inputs.nixpkgs-master {
    system = pkgs.stdenv.hostPlatform.system;
  };

  # 2.0.32 — same version as the workstation (vetymae) runs.
  opencodeV2 = masterPkgs.opencode;

  # Plugin spec. Pinned exactly (no @latest): v2 auto-updates only unpinned
  # specs, and the workstation is pinned to the same version.
  pluginSpec = "oh-my-opencode-slim@3.0.5";

  # Model ids are validated against the provider registry, not against taste.
  # `opencode models` on BOTH the workstation and sapphira lists exactly:
  #   minimax-coding-plan/MiniMax-M3           variants: none, thinking
  #   minimax-coding-plan/MiniMax-M3.1-Flash   variants: (none)
  #   opencode/big-pickle                       variants: (none)
  #   opencode/minimax-m3.1-flash-free         variants: low..max
  # Anything else (MiniMax-M3.1-Flash-Preview, MiniMax-M2.7-highspeed, ...)
  # is NOT in the registry -> ProviderModelNotFoundError. The retired v1
  # plugin config on this host referenced MiniMax-M3.1-Flash-Preview
  # everywhere; that is the same class of bug as the kimi-for-coding
  # incident described in R1.x.
  modelFast = "minimax-coding-plan/MiniMax-M3.1-Flash";

  # nixpkgs ast-grep only ships binary `ast-grep`; omo's ast-grep skill probes
  # for `sg` (or ast-grep). Provide both via a symlink wrapper.
  astGrepWithSg = pkgs.runCommandLocal "ast-grep-with-sg" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/ast-grep
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/sg
  '';

  # Slim plugin config — mirror of the workstation (vetymae):
  # ~/.config/opencode/oh-my-opencode-slim.json
  slimConfig = {
    agents = {
      orchestrator = { model = modelFast; };
      explorer = { model = modelFast; };
      oracle = { model = modelFast; };
      designer = { model = modelFast; };
      fixer = { model = modelFast; };
    };
  };
in
let
  # Extras that must be on PATH for the server:
  #   pkgs.nodejs_22  — npx/npm for MCP servers (webpage-mcp) and npm plugins
  #   pkgs.ast-grep   — `sg` CLI; the plugin's ast-grep skill requires it
  #   pkgs.bun        — plugin CLI / omo doctor
  #   pkgs.gh         — GitHub CLI; plugin's GitHub automation requires it
  extraPackages = [
    pkgs.nodejs_22
    astGrepWithSg
    pkgs.bun
    pkgs.gh
  ];
in
{
  programs.opencode = {
    enable = true;

    # OpenCode 2.0.32 from nixpkgs master (nixos-unstable still ships 1.19.0).
    package = opencodeV2;

    # Extras available to opencode-wrapped (via --suffix PATH on the wrapper).
    extraPackages = extraPackages;

    # ~/.config/opencode/opencode.json
    #
    # V2 schema:
    #   plugins  (plural) — v1 used `plugin` (singular), v2 ignores it
    #   mcp.servers       — v1 used a flat `mcp` map
    #
    # NOTE: HM's MCP integration (programs.mcp.servers -> settings.mcp) is OFF
    # (enableMcpIntegration defaults to false). If it were on, HM would inject
    # the v1 flat shape and overwrite the v2 `mcp.servers` block.
    settings = {
      plugins = [ pluginSpec ];

      # Default model, used "when no session or agent model is selected"
      # (v2 config schema). Without it the v2 CLI picks a model from the
      # registry on its own — `opencode/minimax-m3.1-flash-free`, i.e. the
      # free tier — and sends it explicitly, which OVERRIDES the model of
      # the slim plugin's agents: `oc run --agent orchestrator` then ran on
      # the free model even though `/api/agent` reported
      # `minimax-coding-plan/MiniMax-M3.1-Flash` for that agent (verified on
      # sapphira 2026-10-21 by reading the model of the created message).
      # The workstation has no global `model` key — there the TUI remembers
      # the last used model, which is the paid one; on a fresh server DB
      # there is nothing to remember, hence the explicit default here.
      model = modelFast;

      mcp.servers = {
        webpage = {
          type = "local";
          command = [
            "npx"
            "-y"
            "-p"
            "webpage-mcp@latest"
            "webpage-mcp-stdio"
          ];
        };
      };
    };

    # ~/.config/opencode/tui.json is a v1 concept. v2 reads CLI/TUI prefs from
    # cli.json (declared below). Leave `tui` empty so HM writes no tui.json:
    # a tui.json symlinked into /nix/store is read-only, and v2's automatic
    # tui.json -> cli.json migration would then fail to write.
    tui = { };
  };

  # ~/.config/opencode/cli.json — v2 CLI/TUI preferences.
  # $schema: https://opencode.ai/v2/cli.json
  xdg.configFile."opencode/cli.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/v2/cli.json";
    plugins = [ pluginSpec ];
  };

  # ~/.config/opencode/oh-my-opencode-slim.json — config of the enabled plugin
  # (oh-my-opencode-slim reads its own file, nothing else).
  xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON slimConfig;

  # ~/.config/opencode/service.json — v2 background service registration.
  # The v2 CLI wants a background service; it defaults to port 4096, which is
  # the port our systemd unit serves the web UI on. Two servers on one host
  # also means two writers for ~/.local/share/opencode/opencode.db.
  # => keep the background service off; CLI clients talk to the running unit
  # via `oc` (see below) or `opencode --server http://127.0.0.1:4096`.
  xdg.configFile."opencode/service.json".text = builtins.toJSON {
    disabled = true;
  };

  # Same extras on the user's PATH too, so `omo doctor` and standalone invocations
  # of `sg`, `gh`, `npm`, `npx` work in the user's shell — not only inside
  # the opencode-wrapped binary.
  #
  # Note: `pkgs.bun` deliberately NOT included here — it now lives
  # in `home/modules/herdr-runtime.nix`, which both `home/server.nix` and
  # `home/secondary.nix` import. Avoids a second copy of bun in the
  # user's shell PATH (single source of truth) and means the bun-runtime
  # fix for the herdr-web-ui plugin on NixOS is one place to grep.
  # `oc` — CLI client that talks to the already running server instead of
  # spawning a second one (v2 CLI otherwise wants the background service on
  # 4096, which collides with the systemd unit and the shared opencode.db).
  #
  # The server password is needed: the API speaks HTTP basic auth. It is read
  # from the same sops-managed env file the unit uses (mode 0600, owned by the
  # user), so the secret never lands in a nix store path.
  #
  # `--server` goes AFTER the subcommand: `opencode <cmd> --server <url>`
  # (`opencode --server <url> <cmd>` is not accepted by the v2 parser).
  #
  # And it is only accepted by SOME subcommands. v2 parses it per command:
  # `run`, `attach`, `tui`, `api`, `models`, `agent` take it; `mcp`, `service`,
  # `auth`, `serve`, `plugin` do NOT and fail with
  #   "Unrecognized flag: --server in command opencode plugin list".
  # Those five are local-only commands (they read/write the local config and
  # cache), so they must be called without the server URL — verified on
  # sapphira 2026-10-21.
  home.packages = [
    pkgs.nodejs_22
    astGrepWithSg
    pkgs.gh
    (pkgs.writeShellScriptBin "oc" ''
      export PATH="${lib.makeBinPath extraPackages}:$PATH"
      set -a
      # shellcheck disable=SC1090
      . ${xlib.dirs.opencode-server-env}
      set +a

      server_url="http://127.0.0.1:4096"

      # Local-only subcommands: no server involved, no --server flag.
      case "''${1:-}" in
        mcp|service|auth|serve|plugin)
          exec ${opencodeV2}/bin/opencode "$@"
          ;;
      esac

      # An explicit --server / --standalone from the caller wins.
      for arg in "$@"; do
        case "$arg" in
          --server|--server=*|--standalone)
            exec ${opencodeV2}/bin/opencode "$@"
            ;;
        esac
      done

      # The v2 background service is disabled (service.json), so the server
      # must be the systemd unit. A clear hint beats a connection-refused
      # stack trace when the unit is down.
      if ! (exec 3<>/dev/tcp/127.0.0.1/4096) 2>/dev/null; then
        echo "oc: opencode server on 127.0.0.1:4096 is not reachable." >&2
        echo "oc: start it with: systemctl --user start opencode-web" >&2
        exit 1
      fi

      exec ${opencodeV2}/bin/opencode "$@" --server "$server_url"
    '')
  ];

  # Install the plugin package into the v2 npm cache.
  #
  # v2.0.32 does NOT install plugin packages on server startup: the server
  # only loads what is already in ~/.cache/opencode/npm. A fresh host (or a
  # wiped cache) therefore comes up with the plugin declared in opencode.json
  # but NOT loaded — `opencode plugin list` shows nothing, the plugin's agents
  # and its MCP servers (context7, gh_grep) are missing, and nothing in the
  # logs says why. Verified on sapphira 2026-10-21: the cache was empty after
  # the first start, and `opencode plugin add` populated it.
  #
  # `plugin add` is idempotent here: the plugin is already declared in the
  # (read-only) Nix-managed opencode.json, so the command reports "already
  # configured" and only performs the install. Errors are ignored on purpose —
  # a failed warm-up must not break the activation; the server still works,
  # only the plugin is missing.
  home.activation.installOpencodePlugin = lib.hm.dag.entryAfter [ ] ''
    ${opencodeV2}/bin/opencode plugin add ${pluginSpec} >/dev/null 2>&1 || true
  '';

  # Warm the npx cache for the `webpage` MCP server.
  #
  # The MCP is started as `npx -y -p webpage-mcp@latest webpage-mcp-stdio`.
  # The FIRST such spawn has to download and unpack the package (~200 MB) and
  # the MCP handshake times out long before that finishes — the server then
  # reports the MCP as failed ("Request timed out" / npm ENOTEMPTY on a
  # half-written cache dir). The cache lives in ~/.npm/_npx, which Nix does
  # not manage, so the failure comes back after every cache wipe.
  #
  # Pre-warming at activation makes the first real spawn instant. Failure is
  # ignored on purpose: a missing warm-up must not fail the activation.
  home.activation.warmWebpageMcp = lib.hm.dag.entryAfter [ ] ''
    ${pkgs.nodejs_22}/bin/npx -y -p webpage-mcp@latest true >/dev/null 2>&1 || true
  '';

  # Expose `opencode serve` as a systemd user service. nginx on sapphira
  # proxies https://opencode.zeroq.su -> 127.0.0.1:4096.
  #
  # --hostname 0.0.0.0 binds the listener to every interface (matches the
  # "0.0.0.0" intent; nginx then reverse-proxies 127.0.0.1:4096 internally).
  # --cors https://opencode.zeroq.su lets the browser session reach the
  # server from that origin without CORS rejection.
  # --port 4096 is REQUIRED in v2: the default moved to 4097 (4096 belongs to
  # the v2 background service), and the nginx vhost above proxies to 4096.
  #
  # SECURITY: with no password, anyone reaching the upstream socket gets full
  # opencode. Bind 0.0.0.0 + listener == bridge == shell. The password is
  # supplied via sops-managed EnvironmentFile, declared in modules/users.nix
  # and decrypted to a path hardcoded here (home-manager modules cannot read
  # `config.sops.*` — sops-nix options are NixOS-only).
  programs.opencode.web = {
    enable = true;
    environmentFile = xlib.dirs.opencode-server-env;
    extraArgs = [
      "--hostname"
      "0.0.0.0"
      "--port"
      "4096"
      "--cors"
      "https://opencode.zeroq.su"
    ];
  };

  # RAM constraints for the opencode-web user service.
  #
  # Sapphira has 5.6 GiB RAM with a ~1 GiB baseline (syncthing + immich + gitea
  # + x-ui + nextcloud php-fpm). When something else spikes (immich-ml jobs,
  # syncthing indexer, etc.) the system OOM killer activates and picks the
  # largest cgroup — opencode at ~260 MiB – 1.4 GiB peak was being chosen and
  # systemd then restarted it every few seconds (`RestartSec=5`), masking the
  # real cause as a "service crash". The 2026-10-04 incident was exactly this.
  #
  # Three knobs together make opencode stop being an OOM victim AND stop being
  # the source of an OOM:
  #
  #   MemoryHigh     soft pressure threshold: kernel reclaims aggressively
  #                  once the cgroup hits this. Process keeps running.
  #   MemoryMax      hard cap: cgroup-local OOM kills Node if exceeded. The
  #                  HOST survives — only this process dies, no restart storm.
  #   OOMScoreAdjust negative bias for the system-wide OOM killer: opencode
  #                  is killed last, after syncthing/immich/etc.
  #   OOMPolicy      "continue" — systemd does NOT auto-restart on cgroup
  #                  OOM-kill. Without this, a spike triggers the same
  #                  restart-loop the host saw today.
  #
  # v2 is heavier than v1 (bun runtime + web UI in the same process), so these
  # caps stay.
  #
  # Refs:
  #   https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html
  #   https://www.freedesktop.org/software/systemd/man/systemd.exec.html#OOMScoreAdjust=
  # cgroup/OOM knobs added on top of the [Service] section emitted by
  # `programs.opencode.web`. home-manager unions multiple definitions of the
  # same systemd unit attrset, so ExecStart/Restart/EnvironmentFile from
  # upstream and MemoryHigh/MemoryMax/OOMScoreAdjust/OOMPolicy from here
  # land in the same [Service] block systemd actually reads.
  #
  # NOTE: do NOT use `serviceConfig = { ... }` — home-manager renders that
  # as a literal `[serviceConfig]` section, which systemd silently ignores
  # (`Unknown section 'serviceConfig'. Ignoring.`). The cgroup protection
  # above would never take effect (verified on sapphira, c73a698).
  systemd.user.services.opencode-web.Service = {
    MemoryHigh = "1G";
    MemoryMax = "2G";
    OOMScoreAdjust = -900;
    OOMPolicy = "continue";
  };

  # Workaround: home-manager activation updates the GC root `current-home`
  # only at the very end (line 358 of the generated activate script), AFTER all
  # `home.activation.*` dag entries have run. So we cannot read current-home
  # from a dag entry — it still points to the OLD generation at the time our
  # script executes. Instead, read `new-home`, which the activator writes
  # BEFORE any dag entry runs and which already points at the new generation.
  #
  # The versioned symlink (`home-manager-NN-link`) is found by following
  # `home-manager` one hop rather than hardcoding `home-manager-24-link`,
  # so this keeps working across HM major-version bumps.
  home.activation.relinkHomeManager = lib.hm.dag.entryAfter [ ] ''
    hmVersioned="$(readlink "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
    target="$HOME/.local/state/nix/profiles/$hmVersioned"
    newGen="$(readlink -e "''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/new-home" 2>/dev/null || true)"
    if [[ -n "$hmVersioned" && -n "$newGen" && "$(readlink -f "$target")" != "$newGen" ]]; then
      echo "home-manager: relinking $target -> $newGen"
      ln -sfn "$newGen" "$target"
    fi
  '';
}
