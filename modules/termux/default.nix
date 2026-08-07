{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshdDir = "${config.user.home}/sshd";
  sshdTmpDir = "${config.user.home}/sshd-tmp";
  port = 8022;
  serviceDir = "${config.user.home}/service";

  # runit run-scripts (executable store paths, linked into ~/service).
  sshdRun = pkgs.writeScriptBin "sshd-run" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.openssh}/bin/sshd -f /etc/ssh/sshd_config -D
  '';
  svLogRun = pkgs.writeScriptBin "sv-log-run" ''
    #!${pkgs.runtimeShell}
    mkdir -p ./main
    exec ${pkgs.runit}/bin/svlogd -tt ./main
  '';
  svStart = pkgs.writeScriptBin "sv-start" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.runit}/bin/runsvdir ${serviceDir}
  '';
in
{
  # Minimal sshd server for LAN access (e.g. `ssh epral` from other hosts).
  # nix-on-droid has no systemd: sshd is started manually via `sshd-start`
  # (or from Termux:Boot / a session). The host key is generated once on the
  # first activation and kept in ~/sshd (NOT /etc — it is rebuilt on every
  # activation).
  environment.etc."ssh/sshd_config".text = ''
    HostKey ${sshdDir}/ssh_host_ed25519_key
    Port ${toString port}
    PasswordAuthentication no
    AllowUsers ${config.user.userName}
  '';

  # Generate the host key on first activation (idempotent).
  build.activation.sshd = ''
    if [[ ! -d "${sshdDir}" ]]; then
      $DRY_RUN_CMD rm -rf "${sshdTmpDir}"
      $DRY_RUN_CMD mkdir -p "${sshdTmpDir}"
      $VERBOSE_ECHO "Generating sshd host key..."
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "${sshdTmpDir}/ssh_host_ed25519_key" -N ""
      $DRY_RUN_CMD mv "${sshdTmpDir}" "${sshdDir}"
    fi
  '';

  # nix-on-droid's session-init adds ~/.nix-defexpr/channels to NIX_PATH
  # unconditionally; nix warns about the missing dir on every invocation.
  # Making it exist silences the warning. Must be done in activation (not
  # home-manager): ~/.nix-defexpr/channels is a symlink into
  # ~/.local/state/nix/profiles/channels (dangling until it exists), which
  # home-manager cannot link into. mkdir -p refuses to traverse a dangling
  # symlink, so create the real target dir instead.
  build.activation.nixdefexpr = ''
    $DRY_RUN_CMD mkdir -p "${config.user.home}/.local/state/nix/profiles/channels/nixpkgs"
    $DRY_RUN_CMD touch "${config.user.home}/.local/state/nix/profiles/channels/nixpkgs/.keep"
  '';

  # runit service tree: ~/service/<name>/{run,log/run}. run/ and log/run are
  # symlinks into the nix store (read-only is fine; runsvdir writes only to
  # the <name>/supervise dirs). /etc/service is symlinked for `sv status`.
  # NOTE: tailscaled was removed — nixpkgs' linux build cannot run inside
  # proot (SELinux blocks netlink; needs GOOS=android or root). Re-add only
  # if that gets solved.
  build.activation.services = ''
    $DRY_RUN_CMD rm -rf ${serviceDir}/tailscaled
    $DRY_RUN_CMD mkdir -p ${serviceDir}/sshd/log
    $DRY_RUN_CMD ln -sfn ${sshdRun}/bin/sshd-run ${serviceDir}/sshd/run
    $DRY_RUN_CMD ln -sfn ${svLogRun}/bin/sv-log-run ${serviceDir}/sshd/log/run
    $DRY_RUN_CMD ln -sfn ${serviceDir} /etc/service
  '';

  environment.packages = [
    pkgs.runit

    # one command brings up all supervised services (sshd, ...)
    svStart

    # manual fallback for sshd only
    (pkgs.writeScriptBin "sshd-start" ''
      #!${pkgs.runtimeShell}
      exec ${pkgs.openssh}/bin/sshd -f /etc/ssh/sshd_config -D "$@"
    '')

    # termux-battery-status, termux-notification, termux-clipboard-*, ...
    # Needs the Termux:API Android app (com.termux.api, from F-Droid) as the
    # actual backend; see termux-api.nix.
    (pkgs.callPackage ./termux-api.nix { })
  ];
}
