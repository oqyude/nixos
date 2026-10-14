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
    # systemd's EnvironmentFile (consumed by the upstream NixOS
    # services.gitea-actions-runner module) reads KEY=VALUE lines, not
    # YAML. sops with format = "dotenv" decodes to that — the runner's
    # ExecStartPre script exports `TOKEN="$TOKEN"` from the file. The
    # previous key="registration_token" / format="yaml" combination
    # decoded to a YAML body that EnvironmentFile could not parse, so
    # the runner received no $TOKEN at all and Gitea replied
    # "runner registration token not found".
    path     = "/var/lib/gitea-runner/registration-token";
    format   = "dotenv";
    sopsFile = ../../secrets/gitea-runner-registration.env;
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

      # Workspace in /tmp is tmpfs (size = ~50% of RAM ≈ 2.8 GiB
      # on sapphira), so the default 4 GB threshold would always trip.
      # 256 MiB is plenty for smoke-test workflows and still trips
      # meaningfully if tmpfs truly fills.
      health_check.enabled                = true;
      health_check.min_free_disk_space_mb = 256;
      health_check.interval               = "5m";
      health_check.timeout                = "30s";

      # Workspace in /tmp (tmpfs). Same approach as GH Actions runners —
      # ephemeral, always writable by the runner's UID. Avoids racing with
      # the StateDirectory symlink (private/gitea-runner at mode 700) and
      # the bind-mount from /mnt/services that gets RO during activations.
      #
      # /tmp is tmpfs on NixOS, ~50% of RAM. health_check.min_free_disk_space_mb
      # below this matches reality (sapphira has only ~2.8 GiB tmpfs total).
      host.workdir_parent = "/tmp/gitea-runner-work";

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

  # ----- Workspace directory on tmpfs ---------------------------------------
  # /tmp is by default tmpfs on NixOS, world-writable. The runner's
  # DynamicUser gitea-runner (uid 973) can mkdir directly without any
  # tmpfiles setup. We still add a tmpfiles rule for /tmp/gitea-runner-work
  # so successive deployments don't briefly see an empty target.
  systemd.tmpfiles.rules = xlib.helpers.mkTmpDirs {
    dir   = "/tmp/gitea-runner-work";
    mode  = "1777";          # sticky so different runner invocations don't clobber
    user  = "root";
    group = "root";
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
