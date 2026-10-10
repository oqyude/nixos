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
    config = { allowUnfree = true; };
  };
in
{
  devShells.${system} = {
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

        # Direct executable-path override (honoured by older Playwright and
        # the `channel: "chromium"` code path).
        export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium

        # Playwright 1.40+ uses a separate "chrome-headless-shell" binary
        # in headless mode and looks for it under a hard-coded path
        # ($PLAYWRIGHT_BROWSERS_PATH/chromium_headless_shell-<rev>/...).
        # We satisfy that lookup by symlinking the nixpkgs chromium into a
        # fake registry directory.
        export NIX_CHROMIUM=${pkgs.chromium}/bin/chromium
        export PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/vtimeline-pw-browsers
        mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
        link_bin() {
          local d="$PLAYWRIGHT_BROWSERS_PATH/$1"
          mkdir -p "$d"
          ln -sfn "$NIX_CHROMIUM" "$d/chrome-headless-shell"
          ln -sfn "$NIX_CHROMIUM" "$d/chrome"
        }
        # Layouts derived from Playwright's EXECUTABLE_PATHS table for
        # the chromium + chromium-headless-shell entries (linux-x64).
        link_bin "chromium-1248/chrome-linux"
        link_bin "chromium_headless_shell-1248/chrome-headless-shell-linux64"

        # Convenience banner. The VeeamTimelineView project lives next to
        # this flake repo (../VeeamTimelineView from the nixos checkout,
        # i.e. S:\\Git\\VeeamTimelineView on Windows). We don't bake the
        # path into the shellHook because Nix forbids escaping the flake
        # source dir at eval time — print a hint and let the user `cd`.
        echo "[vtimeline-devshell] node:   $(command -v node)"
        echo "[vtimeline-devshell] python: $(command -v python3)"
        echo "[vtimeline-devshell] chrome: $NIX_CHROMIUM"
        echo "[vtimeline-devshell] run:    cd ../VeeamTimelineView && npm install && npm test"
      '';
    };
  };
}
