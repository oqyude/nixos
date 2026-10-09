# Declarative OpenCode + oh-my-openagent (oh-my-opencode) plugin setup.
#
# Mirrors ~/.config/opencode/ on the current workstation.
# Imported by home/server.nix (sapphira). Auto-enables programs.opencode.
#
# Files this module owns on disk:
#   ~/.config/opencode/opencode.json         <- programs.opencode.settings
#   ~/.config/opencode/tui.json              <- programs.opencode.tui
#   ~/.omo/omo.jsonc                         <- oh-my-openagent plugin's PRIMARY
#                                              runtime config (>= v5.x reads
#                                              only this path; the legacy
#                                              ~/.config/opencode/oh-my-openagent.json
#                                              is read only by the migration shim).
#   ~/.config/opencode/oh-my-openagent.json  <- legacy mirror, kept so omo doctor
#                                              and any downgrade that re-reads
#                                              the old path see the same content.
#
# Override any field in the importing module if needed.
{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  # Body of ~/.omo/omo.jsonc (and the legacy mirror).
  # Loaded by the oh-my-openagent opencode plugin on startup.
  #
  # Plugins >= 5.x resolve their config from ~/.omo/omo.jsonc, NOT from
  # ~/.config/opencode/oh-my-openagent.json. Pinning _migrations here prevents
  # the 2026-07-opencode-config-unification migration from running on every
  # startup and re-backing-up the file (which would otherwise leave us with
  # an empty omo.jsonc that drops every agent override — see the journal entry
  # below).
  ohMyOpenagentConfig = {
    "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/omo.schema.json";
    _migrations = [
      "2026-07-opencode-config-unification"
      "2026-08-reasoning-unification"
    ];

    agents = {
      sisyphus = {
        model = "opencode/claude-opus-5";
        variant = "max";
        fallback_models = [
          { model = "opencode/kimi-k3"; }
          {
            model = "opencode/gpt-5.6-sol";
            variant = "medium";
          }
          { model = "opencode/glm-5"; }
          { model = "opencode/big-pickle"; }
        ];
      };
      hephaestus = {
        model = "opencode/gpt-5.6-sol";
        variant = "medium";
      };
      oracle = {
        model = "opencode/gpt-5.6-sol";
        variant = "xhigh";
        fallback_models = [
          {
            model = "opencode/gemini-3.1-pro";
            variant = "high";
          }
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
        ];
      };
      librarian = {
        model = "minimax-coding-plan/MiniMax-M3";
      };
      explore = {
        model = "opencode/gpt-5-nano";
        fallback_models = [
          { model = "minimax-coding-plan/MiniMax-M3"; }
        ];
      };
      "multimodal-looker" = {
        model = "opencode/gpt-5.6-sol";
        variant = "low";
        fallback_models = [
          { model = "opencode/gpt-5-nano"; }
        ];
      };
      prometheus = {
        model = "opencode/claude-fable-5";
        variant = "high";
        fallback_models = [
          {
            model = "opencode/kimi-k3";
            variant = "high";
          }
        ];
      };
      metis = {
        model = "opencode/claude-opus-5";
        variant = "high";
        fallback_models = [
          {
            model = "opencode/kimi-k3";
            variant = "low";
          }
        ];
      };
      momus = {
        model = "opencode/gpt-5.6-sol";
        variant = "xhigh";
        fallback_models = [
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
          {
            model = "opencode/gemini-3.1-pro";
            variant = "high";
          }
        ];
      };
      atlas = {
        model = "opencode/claude-sonnet-4-6";
        fallback_models = [
          {
            model = "opencode/gpt-5.6-sol";
            variant = "medium";
          }
          { model = "minimax-coding-plan/MiniMax-M3"; }
        ];
      };
      "sisyphus-junior" = {
        model = "opencode/claude-sonnet-4-6";
        fallback_models = [
          {
            model = "opencode/gpt-5.6-sol";
            variant = "medium";
          }
          { model = "minimax-coding-plan/MiniMax-M3"; }
          { model = "opencode/big-pickle"; }
        ];
      };
    };

    categories = {
      "visual-engineering" = {
        model = "opencode/gemini-3.1-pro";
        variant = "high";
        fallback_models = [
          { model = "opencode/glm-5"; }
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
        ];
      };
      ultrabrain = {
        model = "opencode/gpt-5.6-sol";
        variant = "xhigh";
        fallback_models = [
          {
            model = "opencode/gemini-3.1-pro";
            variant = "high";
          }
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
        ];
      };
      deep = {
        model = "opencode/gpt-5.6-sol";
        variant = "medium";
        fallback_models = [
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
          {
            model = "opencode/gemini-3.1-pro";
            variant = "high";
          }
        ];
      };
      artistry = {
        model = "opencode/gemini-3.1-pro";
        variant = "high";
        fallback_models = [
          {
            model = "opencode/claude-opus-5";
            variant = "max";
          }
          {
            model = "opencode/gpt-5.6-sol";
            variant = "high";
          }
        ];
      };
      quick = {
        model = "opencode/gpt-5.4-mini";
        fallback_models = [
          { model = "opencode/gemini-3-flash"; }
          { model = "minimax-coding-plan/MiniMax-M3"; }
          { model = "opencode/gpt-5-nano"; }
        ];
      };
      "unspecified-low" = {
        model = "opencode/claude-sonnet-4-6";
        fallback_models = [
          {
            model = "opencode/gpt-5.6-sol";
            variant = "medium";
          }
          { model = "opencode/gemini-3-flash"; }
          { model = "minimax-coding-plan/MiniMax-M3"; }
        ];
      };
      "unspecified-high" = {
        model = "opencode/claude-sonnet-4-6";
        fallback_models = [
          {
            model = "opencode/gpt-5.6-sol";
            variant = "medium";
          }
          { model = "opencode/gemini-3-flash"; }
          { model = "minimax-coding-plan/MiniMax-M3"; }
        ];
      };
      writing = {
        model = "opencode/gemini-3-flash";
        fallback_models = [
          { model = "opencode/claude-sonnet-4-6"; }
          { model = "minimax-coding-plan/MiniMax-M3"; }
        ];
      };
    };
  };
in
let
  # nixpkgs ast-grep only ships binary `ast-grep`; omo's ast-grep skill probes
  # for `sg` (or ast-grep). Provide both via a symlink wrapper.
  astGrepWithSg = pkgs.runCommandLocal "ast-grep-with-sg" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/ast-grep
    ln -s ${pkgs.ast-grep}/bin/ast-grep $out/bin/sg
  '';
in
{
  programs.opencode = {
    enable = true;

    # Extras available to opencode-wrapped (via --suffix PATH on the wrapper):
    #   pkgs.nodejs_22  — npx/npm for MCP servers (webpage-mcp) and omo's plugin loader
    #   pkgs.ast-grep   — `sg` CLI; omo's ast-grep skill requires it (omo doctor)
    #   pkgs.bun        — omo prefers bun; with bun on PATH, `omo doctor` skips node fallback
    #   pkgs.gh         — GitHub CLI; omo's GitHub automation features require it
    extraPackages = [
      pkgs.nodejs_22
      astGrepWithSg
      pkgs.bun
      pkgs.gh
    ];

    # ~/.config/opencode/opencode.json
    settings = {
      plugin = [ "oh-my-openagent@latest" ];
      mcp = {
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

    # ~/.config/opencode/tui.json
    # Mirrors workstation: oh-my-openagent also registered for the TUI.
    tui = {
      plugin = [ "oh-my-openagent@latest" ];
    };
  };

  # ~/.omo/omo.jsonc — primary file the oh-my-openagent plugin reads at runtime
  # (>= v5.x). This path lives outside XDG_CONFIG_HOME (~/.config), so use
  # home.file rather than xdg.configFile.
  #
  # ~/.config/opencode/oh-my-openagent.json is kept as a legacy mirror so
  # `omo doctor`, the migration shim, and any future downgrade that re-reads the
  # old path see the same content.
  #
  # MIGRATION TRAP (do not just point back at the legacy path):
  #   The plugin runs a `2026-07-opencode-config-unification` migration on every
  #   startup that backs up ~/.omo/omo.jsonc and tries to rewrite it from
  #   ~/.config/opencode/oh-my-openagent.json. The backup directory name embeds
  #   the source's content-hashed store path; because HM does not delete the
  #   previous generation's store path until garbage collection, the same path
  #   is reused on every retry and omo logs "Migration backup path already
  #   exists" forever — meanwhile the user's agent overrides disappear and the
  #   plugin's built-in fallback chain (which references providers like
  #   kimi-for-coding that opencode's provider registry no longer ships) gets
  #   picked instead, surfacing as `ProviderModelNotFoundError:
  #   kimi-for-coding/kimi-for-coding-highspeed` on every subagent spawn.
  #   Pinning _migrations above makes the migration a no-op; the omo.jsonc
  #   below is the actual config the plugin sees.
  home.file."${config.home.homeDirectory}/.omo/omo.jsonc".text = builtins.toJSON ohMyOpenagentConfig;
  xdg.configFile."opencode/oh-my-openagent.json".text = builtins.toJSON ohMyOpenagentConfig;

  # Same extras on the user's PATH too, so `omo doctor` and standalone invocations
  # of `sg`, `gh`, `bun`, `npm`, `npx` work in the user's shell — not only inside
  # the opencode-wrapped binary.
  home.packages = [
    pkgs.nodejs_22
    astGrepWithSg
    pkgs.bun
    pkgs.gh
  ];

  # Expose `opencode web` as a systemd user service. nginx on sapphira
  # proxies https://opencode.zeroq.su -> 127.0.0.1:4096.
  #
  # --hostname 0.0.0.0 binds the listener to every interface (matches the
  # "0.0.0.0" intent; nginx then reverse-proxies 127.0.0.1:4096 internally).
  # --cors https://opencode.zeroq.su lets the browser session reach the
  # server from that origin without CORS rejection.
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
  # Sizes are derived from observed peak (1.4 GiB at 16:36, 1.1 GiB at 16:59).
  # MemoryHigh = 1G gives headroom for normal runs; MemoryMax = 2G caps
  # pathological growth. Tweak both together if a workload legitimately
  # needs more.
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
  home.activation.relinkHomeManager = lib.hm.dag.entryAfter [] ''
    hmVersioned="$(readlink "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
    target="$HOME/.local/state/nix/profiles/$hmVersioned"
    newGen="$(readlink -e "''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/new-home" 2>/dev/null || true)"
    if [[ -n "$hmVersioned" && -n "$newGen" && "$(readlink -f "$target")" != "$newGen" ]]; then
      echo "home-manager: relinking $target -> $newGen"
      ln -sfn "$newGen" "$target"
    fi
  '';
}