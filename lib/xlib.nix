{
  lib,
  ...
}:
# Shared pure helper functions for module definitions.
# Injected into every module via `xlib.helpers` (see options.nix).
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
          "uid=1000"
          "gid=1000"
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
          "uid=1000"
          "gid=1000"
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
}
