{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  name = "ci-sapphira";
  # MUST equal upstream's `nameValuePair "gitea-runner-${escapeSystemdPath name}"`
  # (nixos/modules/services/continuous-integration/gitea-actions-runner.nix:195).
  # `escapeSystemdPath` is not reachable from this flake's lib surface, so the
  # escaped form is spelled out literally: a literal backslash before x2d.
  # The `assertions` entry below fails the build if this ever drifts.
  unitKey = "gitea-runner-ci\\x2dsapphira";
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
      # scripts/update-manifest.sh in oqyude/winos hard-requires jq
      # ("for dep in curl jq") and the runner's PATH is exactly this list.
      jq
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
  # THE ATTRIBUTE NAME BELOW IS NOT COSMETIC — read before touching it.
  #
  # Upstream registers the unit as
  #     nameValuePair "gitea-runner-${escapeSystemdPath name}" { ... }
  # so the systemd.services key is `gitea-runner-ci\x2dsapphira` — with a
  # LITERAL backslash-x-2-d, not a plain hyphen. Both forms render to the
  # same file `gitea-runner-ci-sapphira.service`, but they are two
  # separate attrsets.
  #
  # Writing the unescaped key (as e6e82b8 and its predecessors did) creates
  # a PHANTOM second unit that carries only our overrides and no ExecStart.
  # The phantom wins the render, and systemd then refuses to start:
  #     "Service has no ExecStart=, ExecStop=, or SuccessAction=. Refusing."
  # The real symptom was on sapphira from 2026-10-14 16:25; e6e82b8 did not
  # fix it.
  #
  # The earlier post-mortem blamed the SECTION ([Unit] merges, [Service]
  # does not). That was wrong and is what kept the bug alive across three
  # attempts. `unitConfig` and `serviceConfig` are ordinary leaves of the
  # same submodule; with a correct key either merges fine. Build the key
  # the same way upstream does so a future rename cannot silently
  # re-fork the unit.
  #
  # Cgroup caps (CPUQuota / MemoryMax / Nice / IO) are deliberately NOT
  # set here — revisit only after this unit verifiably starts.
  #
  # DEPENDENCY MODEL (replaces the storage guard, which never fitted this
  # unit). Verified on sapphira against the live process:
  #   cwd  -> /var/lib/private/gitea-runner/ci-sapphira   (rootfs)
  #   workdir_parent -> /tmp/gitea-runner-work            (tmpfs)
  #   token -> /var/lib/gitea-runner/registration-token   (rootfs)
  #   open fds on /mnt/services or ~/External: none
  # So the runner touches NOTHING on the external disk and the old
  # ConditionPathIsMountPoint guarded an empty set. Worse, it was an
  # availability hazard: with Restart=no, a boot where the disk mounted
  # after systemd evaluated the condition skipped the unit permanently
  # (observed: down 2026-10-14 16:25 .. 2026-10-15, never retried).
  #
  # Its REAL dependency is the Gitea endpoint: ExecStartPre runs
  #   gitea-runner register --instance https://git.zeroq.su/
  # which is nginx -> gitea (php-fpm). Hence Wants+After on both.
  #
  # `Wants`, not `Requires`: `After=` only means "started", not "serving".
  # nginx itself is After=acme-git.zeroq.su.service, so TLS may not be
  # provisioned yet at the moment we would start. Wants lets us try early;
  # Restart=on-failure below supplies the retry loop that Restart=no lacked.
  # (Requires would CANCEL our start job on gitea failure, and a cancelled
  # job never triggers Restart — the opposite of what we want here.)
  systemd.services.${unitKey} = {
    # Top-level unit options, exactly how upstream declares them. Putting
    # these inside `unitConfig` instead silently drops them: unitConfig is a
    # freeform [Unit] passthrough, and `wants`/`after` are first-class
    # options that take precedence (ConditionPathIsMountPoint rendered fine
    # from unitConfig; these two did not — verified against the built unit).
    wants = lib.mkAfter [
      "nginx.service"
      "gitea.service"
    ];
    after = lib.mkAfter [
      "nginx.service"
      "gitea.service"
      "local-fs.target"
      "systemd-tmpfiles-setup.service"
    ];

    # [Service] side. This merge is only safe because `unitKey` now matches
    # upstream — the phantom-key bug looked exactly like "serviceConfig cannot
    # merge" and was the reason e6e82b8 wrongly ruled this mechanism out.
    #
    # Upstream ALREADY sets Restart="on-failure" (and RestartSec=2), so only
    # the retry interval is forced here: 2s is tuned for "gitea restarted
    # mid-upgrade", but with a soft Wants on nginx/gitea we also now retry
    # through ordinary boot and TLS-provisioning lag, which would spin the
    # journal at 2s intervals. Restart itself is left to upstream.
    serviceConfig = {
      RestartSec = lib.mkForce "30s";
    };
  };

  # Tripwire. The phantom-unit failure mode above is silent: it activates
  # cleanly, the system boots, and only systemd's runtime refusal reveals it
  # (it already shipped broken across three commits, 2026-10-14..15).
  # A missing ExecStart on this unit means `unitKey` no longer matches
  # upstream's escaped name and the unit has forked again.
  assertions = [
    {
      assertion = (config.systemd.services.${unitKey}.serviceConfig.ExecStart or null) != null;
      message = ''
        gitea-runner unit "${unitKey}" has no ExecStart.
        `unitKey` no longer matches upstream's escapeSystemdPath name, so this
        override is forking a phantom unit that shadows the real one and systemd
        will refuse to start it ("Service has no ExecStart=... Refusing.").
        Upstream registers it as nameValuePair
        "gitea-runner-" + escapeSystemdPath name.
      '';
    }
  ];
}
