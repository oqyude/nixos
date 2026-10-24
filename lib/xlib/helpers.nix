{
  lib,
  # The primary user's ids, bound from xlib.device by mkXlib. ntfs3/exfat
  # volumes carry POSIX ids, so a mount using anything other than the real
  # uid/gid shows every file as owned by `nobody`.
  uid,
  gid,
  ...
}:
# Pure helper functions for module definitions.
# Injected into every module via `xlib.helpers` (see default.nix).
#
# Defined in a `let` because they reference each other (mkTmpDirs uses
# mkTmpfile, mkServiceStorage uses mkTmpDirs + mkSystemdBind).
let
  # tmpfiles rule: "type dir mode user group -"
  mkTmpfile =
    type: dir: mode: user: group:
    "${type} ${dir} ${mode} ${user} ${group} -";

  # several tmpfiles types for the same dir, e.g. ["d" "z"] or ["d" "Z"]
  mkTmpDirs =
    {
      dir,
      mode,
      user,
      group,
      types ? [
        "d"
        "z"
      ],
    }:
    map (type: mkTmpfile type dir mode user group) types;

  # fileSystems bind mount
  mkBindMount =
    {
      what,
      where,
    }:
    {
      "${where}" = {
        device = what;
        fsType = "none";
        options = [
          "bind"
          "nofail"
        ];
      };
    };

  # systemd.mounts bind mount (automount variant)
  mkSystemdBind =
    {
      what,
      where,
    }:
    {
      enable = true;
      options = "bind,x-systemd.automount,nofail";
      requires = [ "local-fs.target" ];
      type = "none";
      wantedBy = [ "multi-user.target" ];
      inherit what where;
    };

  # Full "service storage" block: services-mnt source dir + /var/lib target,
  # tmpfiles d/z + automount bind. Used as:
  #   storage = xlib.helpers.mkServiceStorage { name = "x"; user = "x"; group = "x"; };
  #   systemd = storage.systemd;
  mkServiceStorage =
    {
      name,
      user,
      group,
      mode ? "0755",
      target ? "/var/lib/${name}",
      base ? "/mnt/services",
    }:
    let
      sourceDir = "${base}/${name}";
    in
    {
      inherit sourceDir target;
      systemd = {
        tmpfiles.rules = mkTmpDirs {
          dir = sourceDir;
          inherit mode user group;
        };
        mounts = [
          (mkSystemdBind {
            what = sourceDir;
            where = target;
          })
        ];
      };
    };

  # ntfs3 mount, e.g. fileSystems = mkNtfsMount { path = ...; uuid = ...; }
  mkNtfsMount =
    {
      path,
      uuid,
      mask ? "0007",
      enable ? null,
    }:
    {
      "${path}" = {
        device = "/dev/disk/by-uuid/${uuid}";
        fsType = "ntfs3";
        options = [
          "defaults"
          "uid=${toString uid}"
          "gid=${toString gid}"
          "fmask=${mask}"
          "dmask=${mask}"
          "nofail"
        ];
      }
      // lib.optionalAttrs (enable != null) { inherit enable; };
    };

  # exfat mount, e.g. fileSystems = mkExfatMount { path = ...; uuid = ...; }
  mkExfatMount =
    {
      path,
      uuid ? null,
      label ? null,
    }:
    {
      "${path}" = {
        device = if uuid != null then "/dev/disk/by-uuid/${uuid}" else "/dev/disk/by-label/${label}";
        fsType = "exfat";
        options = [
          "nofail"
          "uid=${toString uid}"
          "gid=${toString gid}"
        ];
      };
    };

  # home-manager out-of-store symlinks: path = source (target name = attr name)
  mkSymlinks =
    config: paths:
    lib.mapAttrs' (sourcePath: targetPath: {
      name = targetPath;
      value.source = config.lib.file.mkOutOfStoreSymlink "${sourcePath}";
    }) paths;
in
{
  inherit
    mkTmpfile
    mkTmpDirs
    mkBindMount
    mkSystemdBind
    mkServiceStorage
    mkNtfsMount
    mkExfatMount
    mkSymlinks
    ;

  # Storage guard. Returns a systemd **unitConfig** fragment (the `[Unit]`
  # section) that prevents a service from starting when the external storage
  # filesystem (`xlib.dirs.server-home` = `/home/$user/External`) is not
  # actually mounted. Without this guard, services whose `stateDir` /
  # `dataDir` / bind mount source is a subdir of `/mnt/services` would happily
  # start on an empty bind mount and create a fresh empty database — silent
  # data loss. See T4 (B1) in `.agent/tasks/manifest.json` and R1.2 in
  # `.agent/rules/project-rules.md`.
  #
  # Why this anchor: bind mounts under `/mnt/services` are inside the
  # same filesystem as External, so `ConditionPathIsMountPoint` on those
  # paths always reports "yes" (st_dev matches) — useless. We anchor on
  # `server-home` (the real mount) instead.
  #
  # (a) Why `unitConfig` and NOT `serviceConfig`: `ConditionPathIsMountPoint`
  #     is a `[Unit]` directive. Injected through `serviceConfig` it is
  #     rendered into `[Service]`, where systemd does not read it — the guard
  #     is silently dead (T4: 13 units / 12 services on sapphira).
  #     `unitConfig` is the only injection point that lands in `[Unit]`.
  #
  # (b) Why `RequiresMountsFor` is deliberately absent: it would make systemd
  #     auto-mount the filesystem when the unit is started, which defeats the
  #     guard — the unit would start because systemd mounted the disk, not
  #     because the disk was already there (tested and confirmed: v8 test on
  #     sapphira, 2026-10-10). Ordering belongs into `After=` on the .mount
  #     unit in the consumer's `systemd.services` block, not into a
  #     guard-creating dependency here.
  #
  # (c) Why the `vds` device type is excluded: a VDS has no External disk at
  #     all. On otreca `/home/oqyude/External` does not even exist
  #     (`ls` → "No such file or directory", `findmnt` → not a mount point;
  #     verified 2026-10-25) and every service keeps its data on the root
  #     filesystem (`/mnt/services` is a plain directory there, not a bind
  #     mount of the External disk as on sapphira). A *live* condition on such
  #     a host is not just useless, it is destructive: systemd would skip the
  #     unit, and the 3x-ui panel (`podman-3xui_app`, the only guarded unit
  #     reachable from `modules/vds`) would never start — killing the panel
  #     at `pubray1.zeroq.su`. Hence: guard only where the disk exists.
  #
  # Usage in a service module:
  #   systemd.services.<name>.unitConfig = xlib.helpers.mkStorageGuard xlib;
  # On a `vds` host this evaluates to `{}` — an empty `unitConfig`, which is
  # a valid value (`unitConfig` is `attrsOf`) and simply adds no condition.
  # The unit name must be the REAL unit of the service (e.g. `samba-smbd`,
  # `phpfpm-nextcloud`, `immich-server`) — see ADR-0004: a wrong key renders a
  # phantom unit with no ExecStart, and systemd refuses to start it.
  mkStorageGuard = xlib:
    lib.optionalAttrs (xlib.device.type != "vds") {
      # Guard via ConditionPathIsMountPoint ONLY — see (b) above for why
      # RequiresMountsFor must NOT be added.
      ConditionPathIsMountPoint = [ xlib.dirs.server-home ];
    };
}
