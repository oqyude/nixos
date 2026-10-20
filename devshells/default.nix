# Per-project devshells. Each entry here is a self-contained mkShell that
# can be entered with `nix develop .#<name>`.
#
# Why this lives in the nixos flake:
#   vtimeline is a sibling project under /s/Git/VeeamTimelineView (not part
#   of the NixOS configs). Keeping its devshell here avoids polluting the
#   project itself with a flake, while still letting us `nix develop` into
#   the same node/python/chromium toolchain that NixOS uses.
{ inputs, ... }@_flakeContext:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  devShells.${system} = {
    # `nix develop .#ci` -> the tool set a Gitea Actions job on sapphira
    # needs. Same list as the runner's hostPackages (lib/ci-tools.nix), so a
    # workflow can get the tools it needs without a nixos-rebuild:
    #
    #   nix develop /etc/nixos#ci --command bash -c 'echo $PATH'
    #
    # The runner's own PATH is fixed in the systemd unit at activation time,
    # and changing it needs `nixos-rebuild switch` on the host. The workflows
    # in oqyude/winos therefore take the PATH from this devshell instead --
    # jq (scripts/update-manifest.sh) and pwsh (scripts/update-kvrt.ps1) are
    # not in the runner's default set, and `nix-shell -p` is not a fallback
    # on sapphira (empty nix registry, no channels).
    ci = pkgs.mkShell {
      name = "gitea-ci-devshell";

      buildInputs = import ../lib/ci-tools.nix { inherit pkgs; };

      shellHook = ''
        echo "[ci-devshell] jq:   $(command -v jq || echo MISSING)"
        echo "[ci-devshell] pwsh: $(command -v pwsh || echo MISSING)"
      '';
    };

    # `nix develop .#vtimeline` -> shell for testing the VeeamTimelineView
    # project (Playwright + ESLint + Prettier over a vanilla-JS frontend).
    vtimeline = pkgs.mkShell {
      name = "vtimeline-devshell";

      buildInputs = with pkgs; [
        # nodejs_20 was removed from nixpkgs on 2026-07-13 after Node.js 20
        # reached upstream EOL on 2026-04-30. nodejs_22 is the current LTS.
        # VeeamTimelineView's package.json does not pin a Node version, so
        # this is transparent to npm.
        nodejs_22
        python3
        chromium
      ];

      # `nodePackages.*` deliberately not added — they would pollute the
      # shell globally. Anything npm-side goes through `npm install` in the
      # project's own node_modules.

      shellHook = ''
        # Skip Playwright's own browser download — we use the system one.
        export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

        export NIX_CHROMIUM=${pkgs.chromium}/bin/chromium
        # NOTE: there is deliberately no PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH
        # export. Playwright never reads that variable — verified 2026-10-12:
        # no reference to it anywhere in playwright-core, and pointing
        # PLAYWRIGHT_BROWSERS_PATH at an empty directory fails the suite even
        # while the variable is set. The symlink farm below is the only thing
        # that makes Playwright use the nixpkgs chromium. Don't re-add it.
        export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/vtimeline-pw-browsers"
        mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"

        # Locate the project. It is a sibling git repo, NOT a flake input, so
        # the path can only be resolved when the shell starts — Nix forbids
        # baking a path outside the flake source into the store path. sapphira
        # keeps it on the external disk, Windows hosts use S:\Git.
        VT_PROJECT=""
        for cand in "$HOME/External/Git/VeeamTimelineView" \
                    "$HOME/Git/VeeamTimelineView" \
                    "$HOME/Projects/VeeamTimelineView" \
                    "/s/Git/VeeamTimelineView"; do
          if [ -d "$cand" ]; then VT_PROJECT="$cand"; break; fi
        done
        export VT_PROJECT

        # Playwright resolves the browser through a revision-pinned directory
        # name (chromium-<rev>). Hardcoding the revision silently breaks the
        # next time the project bumps @playwright/test, so read the revisions
        # from the project's own playwright-core/browsers.json (node is in
        # this shell) and link the nixpkgs chromium into that layout.
        pw_browser_dirs() {
          local json="$VT_PROJECT/node_modules/playwright-core/browsers.json"
          [ -n "$VT_PROJECT" ] && [ -f "$json" ] || return 1
          node -e '
            const b = require(process.argv[1]);
            const LAYOUT = {
              chromium: "chromium-REV/chrome-linux",
              "chromium-headless-shell": "chromium_headless_shell-REV/chrome-headless-shell-linux64",
            };
            for (const x of b.browsers) {
              const tpl = LAYOUT[x.name];
              if (!tpl) continue;
              console.log(tpl.replace("REV", x.revision));
            }
          ' "$json"
        }

        if pw_dirs=$(pw_browser_dirs) && [ -n "$pw_dirs" ]; then
          while IFS= read -r sub; do
            [ -n "$sub" ] || continue
            mkdir -p "$PLAYWRIGHT_BROWSERS_PATH/$sub"
            # Both names in both layouts: Playwright picks one per code path,
            # and a stale extra symlink costs nothing.
            ln -sfn "$NIX_CHROMIUM" "$PLAYWRIGHT_BROWSERS_PATH/$sub/chrome"
            ln -sfn "$NIX_CHROMIUM" "$PLAYWRIGHT_BROWSERS_PATH/$sub/chrome-headless-shell"
          done <<< "$pw_dirs"
        else
          echo "[vtimeline-devshell] WARNING: no playwright-core/browsers.json under \$VT_PROJECT." >&2
          echo "[vtimeline-devshell]          Run 'npm install' in the project, else" >&2
          echo "[vtimeline-devshell]          Playwright will not find a browser." >&2
        fi

        # Convenience banner.
        echo "[vtimeline-devshell] node:    $(command -v node)"
        echo "[vtimeline-devshell] python:  $(command -v python3)"
        echo "[vtimeline-devshell] chrome:  $NIX_CHROMIUM"
        if [ -n "$VT_PROJECT" ]; then
          echo "[vtimeline-devshell] project: $VT_PROJECT"
          echo "[vtimeline-devshell] run:     cd \"\$VT_PROJECT\" && npm install && npm test"
        else
          echo "[vtimeline-devshell] project: NOT FOUND"
          echo "[vtimeline-devshell]          export VT_PROJECT=/path/to/VeeamTimelineView"
        fi
      '';
    };
  };
}
