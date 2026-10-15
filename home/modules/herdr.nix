# Unattended herdr (https://herdr.dev) agent orchestrator running as a
# systemd USER service on sapphira. Matches the orchestrator's per-UID
# design: Unix sockets live in $XDG_CONFIG_HOME/herdr/ with mode 0600,
# owner-only. See .agent/context/research-herdr-2026-10.md for the full
# architecture assessment.
#
# Why user service, not system:
#   - herdr stores Unix sockets (API + client) in $XDG_CONFIG_HOME/herdr/
#     with mode 0600 and owner-only access. A system service would run
#     under a different uid, so the human user could not reach the API
#     without sudo and there is no benefit to running it as a dedicated
#     uid (herdr itself holds no secrets — see "Credentials" below).
#   - herdr's design is per-UID: one server per user, configurable session
#     namespaces via --session. A system service would fight the tool.
#   - The existing opencode-web service on sapphira (home/modules/opencode.nix)
#     is already a user service; this module mirrors that pattern exactly.
#
# Why --session herdr-prod:
#   - herdr's default session name is fixed at $XDG_CONFIG_HOME/herdr/;
#     using --session namespaced it under sessions/herdr-prod/. This lets
#     a TUI `herdr` client run interactively on sapphira (e.g. for ad-hoc
#     debugging) without colliding with the unattended server's sockets.
#     (Background: herdr issue #4544 — default socket path is fixed, so
#     parallel/automated herdr workloads land on the user's live server.)
#
# Children OpenCode instances (integration-managed, see integrations docs):
#   - herdr spawns `opencode serve` per worktree on demand via the built-in
#     opencode integration. Those children inherit the parent env, so
#     EnvironmentFile below covers both herdr and its opencode children.
#   - This deliberately bypasses the shared background `opencode serve`
#     service that the existing opencode-web systemd user unit uses. Per
#     opencode issue #55076 (severity:high, reproduced, ~$24 runaway),
#     the shared background service resumes killed sessions without their
#     original permissions or step limits. herdr-managed opencode children
#     are scoped to herdr's lifetime, so a herdr restart cleanly drops them.
#
# Credentials:
#   - herdr stores NO secrets. Per herdr docs/integrations/, each agent
#     (OpenCode, Claude, Codex, etc.) reads its own config from its own
#     XDG paths (~/.config/opencode/, ~/.claude/, ~/.codex/, ...). herdr
#     only propagates the parent process env to child panes. So the
#     EnvironmentFile below is the same one used by opencode-web
#     (modules/users.nix:117-122), and the sops-managed OpenCode auth/
#     account JSON files (modules/users.nix:128-141) are read by the
#     spawned OpenCode children on their own — no extra wiring here.
{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  # Install herdr binary. nixpkgs already installs bash/fish/zsh shell
  # completions via installShellCompletion in the package's postInstall
  # (verified: pkgs/by-name/he/herdr/package.nix).
  home.packages = [ pkgs.herdr ];

  # systemd user service: headless `herdr server` running in the
  # dedicated `herdr-prod` session namespace.
  #
  # Why Type=simple (not notify): upstream herdr does not implement
  # sd_notify (no such call in src/platform/unix_common.rs:338-365).
  # Readiness is implied by socket creation in
  # $XDG_CONFIG_HOME/herdr/sessions/herdr-prod/ (mode 0600, owner oqyude).
  #
  # Why Restart=always (not on-failure): herdr issue #4920 — the server
  # can shut down after the last client detaches on some paths.
  # Restart=always guarantees the unattended daemon stays up; systemd
  # de-bounces spurious exits via RestartSec.
  systemd.user.services.herdr = {
    Unit = {
      Description = "herdr agent orchestrator (production session, sapphira)";
      Documentation = [
        "https://herdr.dev/docs/"
        "https://herdr.dev/docs/socket-api/"
        "https://herdr.dev/docs/session-state/"
      ];
      # Spawned children may open Tailscale / LAN sockets (e.g. for the
      # built-in opencode integration that needs to reach other hosts).
      # Wait for routable network so they don't race NetworkManager-wait-online.
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.herdr} server --session herdr-prod";
      Restart = "always";
      RestartSec = "5s";
      # EnvironmentFile is decrypted by sops-nix (modules/users.nix:117-122)
      # to xlib.dirs.opencode-server-env. Contains OPENCODE_SERVER_PASSWORD
      # and any other env vars the spawned `opencode serve` children need.
      # herdr propagates parent process env to child panes (verified:
      # src/session.rs:171-187), so this single EnvironmentFile covers
      # both the orchestrator and its integration-managed OpenCode
      # instances. herdr itself stores NO secrets.
      EnvironmentFile = xlib.dirs.opencode-server-env;
      # Memory protection, same pattern as opencode-web
      # (home/modules/opencode.nix:407-412). sapphira has 5.6 GiB RAM
      # with ~1 GiB baseline; herdr's cgroup covers itself AND its
      # spawned opencode subprocesses, so the budget is available
      # headroom minus a 1.5 GiB cushion for the rest of the host.
      # Sizes are conservative; bump together if a workload legitimately
      # needs more.
      MemoryHigh = "2G";
      MemoryMax = "4G";
      OOMScoreAdjust = -900;
      OOMPolicy = "continue";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}