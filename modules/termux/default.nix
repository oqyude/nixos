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

  environment.packages = [
    (pkgs.writeScriptBin "sshd-start" ''
      #!${pkgs.runtimeShell}
      exec ${pkgs.openssh}/bin/sshd -f /etc/ssh/sshd_config -D "$@"
    '')
  ];
}
