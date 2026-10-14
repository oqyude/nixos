{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  name = "ci-sapphira";
in
{
  # ----- Static user for the runner ----------------------------------------
  users.users.gitea-runner = {
    isSystemUser = true;
    group        = "gitea-runner";
    home         = "/var/lib/gitea-runner";
    description  = "Gitea Actions Runner (sapphira host executor)";
  };
  users.groups.gitea-runner = { };

  # ----- Registration token (Gitea-issued one-shot credential) -------------
  # Stored on the root filesystem, NOT on the external disk: sops writes
  # the file at activation time, and would otherwise land on `/mnt/services`
  # when the external disk happens to be offline during a rebuild — the
  # bind mount would then cover it and silently drop the token on remount.
  # See invariants #2 (external disk mount order) and #7 (sops path).
  sops.secrets.gitea-runner-registration = {
    path     = "/var/lib/gitea-runner/registration-token";
    format   = "yaml";
    key      = "registration_token";
    sopsFile = ../../secrets/gitea-runner-registration.yaml;
    owner    = "gitea-runner";
    group    = "gitea-runner";
    mode     = "0440";
  };

  # ----- The runner itself -------------------------------------------------
  services.gitea-actions-runner.instances."${name}" = {
    enable    = true;
    name      = name;
    url       = "https://git.zeroq.su/"; # matches modules/server/gitea.nix ROOT_URL
    tokenFile = config.sops.secrets.gitea-runner-registration.path;
    labels    = [ "native:host" ]; # only host-executor; no docker required

    settings = {
      runner.capacity              = 1; # sequential on 2-core host
      runner.timeout               = "2h";
      runner.workdir_cleanup_age   = "48h";
      runner.idle_cleanup_interval = "20m";

      # Localhost-only. Co-resident processes can still reach it; scrape
      # via ssh+localhost if ever needed.
      metrics.enabled = true;
      metrics.addr    = "127.0.0.1:9101";

      # eMMC has <64 GB total and no separate data partition — refuse to
      # start a job when free space drops below 4 GB.
      health_check.enabled                = true;
      health_check.min_free_disk_space_mb = 4096;
      health_check.interval               = "5m";
      health_check.timeout                = "30s";

      # Workspace on external disk — storage guard (above) keeps the
      # daemon off an empty bind mount on first boot.
      host.workdir_parent = "${xlib.dirs.services-mnt-folder}/gitea-runner-work";

      # Defence in depth even though host labels never pull images.
      container.docker_host = "";
      container.network     = "";
      container.privileged  = false;
      container.options     = "";
    };

    # Default set (bash, coreutils, curl, gawk, gitMinimal, gnused,
    # nodejs, wget) plus what ZeroQ workflows are most likely to need.
    hostPackages = with pkgs; [
      bash coreutils curl gawk gitMinimal gnused nodejs wget
      nix
      python3
      cacert
    ];
  };

  # ----- Workspace directory on external disk ------------------------------
  # `d` creates if missing; `z` resets ownership if missing — guards the
  # race where the external disk is detached mid-rebuild.
  systemd.tmpfiles.rules = xlib.helpers.mkTmpDirs {
    dir   = "${xlib.dirs.services-mnt-folder}/gitea-runner-work";
    mode  = "0755";
    user  = "gitea-runner";
    group = "gitea-runner";
  };

  # ----- Service unit overrides -------------------------------------------
  # Upstream `services.gitea-actions-runner` produces a full
  # systemd.services.gitea-runner-ci-sapphira attrset (ExecStart,
  # ExecStartPre registration, LoadCredential, User, Restart, etc.).
  # Leaf-level overrides like `systemd.services.X.serviceConfig.Y = Z`
  # were tried (and `lib.mkMerge` of full sub-attrset); both silently
  # replaced the upstream submodule instead of merging, so the unit
  # came out without ExecStart. Cgroup caps + storage guard are now
  # applied through (a) the [Unit] side which actually merges, and
  # (b) deferred — see follow-up todo for the systemd drop-in that
  # reintroduces CPUQuota / MemoryMax / DynamicUser=false.
  #
  # No `RequiresMountsFor` (would defeat the storage guard) — see inline
  # comment in lib/xlib/helpers.nix:180-189. `ConditionPathIsMountPoint`
  # lives in [Unit], so the guard only fires correctly here, not via
  # mkStorageGuard which historically writes it to serviceConfig.
  systemd.services.gitea-runner-ci-sapphira.unitConfig = {
    ConditionPathIsMountPoint =
      (xlib.helpers.mkStorageGuard xlib).ConditionPathIsMountPoint;
    After = [
      "local-fs.target"
      "systemd-tmpfiles-setup.service"
    ];
  };
}
