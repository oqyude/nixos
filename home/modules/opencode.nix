# Declarative OpenCode + oh-my-openagent (oh-my-opencode) plugin setup.
#
# Mirrors ~/.config/opencode/ on the current workstation.
# Imported by home/server.nix (sapphira). Auto-enables programs.opencode.
#
# Three files this module owns on disk (via xdg.configFile):
#   ~/.config/opencode/opencode.json         <- programs.opencode.settings
#   ~/.config/opencode/tui.json              <- programs.opencode.tui
#   ~/.config/opencode/oh-my-openagent.json  <- oh-my-openagent plugin config
#
# Override any field in the importing module if needed.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Body of ~/.config/opencode/oh-my-openagent.json.
  # Loaded by the oh-my-openagent opencode plugin on startup.
  ohMyOpenagentConfig = {
    "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

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

  # ~/.config/opencode/oh-my-openagent.json — read by the plugin on startup.
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
    environmentFile = "${config.home.homeDirectory}/.config/opencode/server.env";
    extraArgs = [
      "--hostname"
      "0.0.0.0"
      "--cors"
      "https://opencode.zeroq.su"
    ];
  };

  # Workaround: home-manager activation updates the GC root `current-home`
  # only at the very end (line 358 of the generated activate script), AFTER all
  # `home.activation.*` dag entries have run. So we cannot read current-home
  # from a dag entry — it still points to the OLD generation at the time our
  # script executes. Instead, read `new-home`, which the activator writes
  # BEFORE any dag entry runs and which already points at the new generation.
  home.activation.relinkHomeManager = lib.hm.dag.entryAfter [] ''
    target="$HOME/.local/state/nix/profiles/home-manager-24-link"
    newGen="$(readlink -e "''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/new-home" 2>/dev/null || true)"
    if [[ -n "$newGen" && "$(readlink -f "$target")" != "$newGen" ]]; then
      echo "home-manager: relinking $target -> $newGen"
      ln -sfn "$newGen" "$target"
    fi
  '';
}