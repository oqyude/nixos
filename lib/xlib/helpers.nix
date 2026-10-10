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

  # Storage guard. Returns a systemd serviceConfig fragment that prevents
  # a service from starting when the external storage filesystem
  # (`xlib.dirs.server-home` = `/home/$user/External`) is not actually
  # mounted. Without this guard, services whose `stateDir` / `dataDir` /
  # bind mount source is a subdir of `/mnt/services` would happily start
  # on an empty bind mount and create a fresh empty database — silent
  # data loss. See T4 (B1) in `.agent/tasks/manifest.json` and R1.2 in
  # `.agent/rules/project-rules.md`.
  #
  # Why this anchor: bind mounts under `/mnt/services` are inside the
  # same filesystem as External, so `ConditionPathIsMountPoint` on those
  # paths always reports "yes" (st_dev matches) — useless. We anchor on
  # `server-home` (the real mount) instead.
  #
  # Usage in a service module:
  #   systemd.services.<name>.serviceConfig = xlib.helpers.mkStorageGuard xlib;
  # or merge with an existing serviceConfig:
  #   serviceConfig = xlib.helpers.mkStorageGuard xlib // { ...other fields... };
  mkStorageGuard = xlib: {
    RequiresMountsFor = [ xlib.dirs.server-home ];
    ConditionPathIsMountPoint = [ "!${xlib.dirs.server-home}" ];
  };
}
