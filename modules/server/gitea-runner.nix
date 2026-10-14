{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  name = "ci-sapphira";
  serviceName = "gitea-runner-${name}";

  # Caps for a background-slow runner on sapphira. Pattern after
  #   - home/modules/opencode.nix:410 (RAM/OOM knobs on opencode-web)
  #   - modules/server/systemd.nix:24 (CPU/IO knobs on rsync-archivesta)
  # The runner is meant to be the FIRST thing the OOM killer picks if
  # something bigger (immich-ML, onlyoffice, syncthing indexer) needs RAM.
  runnerServiceConfig = lib.mkMerge [
    (xlib.helpers.mkStorageGuard xlib)
    {
      # Static user (declared below) instead of ephemeral DynamicUser, so
      # the daemon has a stable UID that can own the sops-decrypted token.
      DynamicUser          = lib.mkForce false;
      Group                = "gitea-runner";

      CPUQuota             = "15%"; # ~0.3 core — never starve nix-daemon
      MemoryHigh           = "384M"; # soft backpressure on $HOME/cache
      MemoryMax            = "512M"; # hard cap, ~10× smaller than opencode
      Nice                 = 19; # lowest priority
      IOWeight             = 10;
      IOSchedulingClass    = "idle";
      IOSchedulingPriority = 7;
      OOMScoreAdjust       = 500; # killed FIRST if host OOMs
      OOMPolicy            = "continue"; # never restart-loop on cgroup OOM
    }
  ];
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
  # The upstream NixOS module already sets DynamicUser=true, LoadCredential,
  # ExecStartPre (re-register on token change), ExecStart, etc. We override
  # with mkMerge so those defaults survive and our caps + storage guard
  # are added.
  #
  # No `RequiresMountsFor` (would defeat the storage guard) — see inline
  # comment in lib/xlib/helpers.nix:180-189. `After= local-fs.target`
  # instead so fstab mounts are up before the unit's Condition check.
  systemd.services."${serviceName}" = {
    serviceConfig = runnerServiceConfig;
    unitConfig.After = [
      "local-fs.target"
      "systemd-tmpfiles-setup.service"
    ];
  };
}
