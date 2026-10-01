{
  lib,
  ...
}:
# Pure host library: no module system involved.
#
# `mkXlib` derives everything a host needs to know about itself (identity,
# well-known paths, capability flags, shared helpers) from a single record.
# It is built in flake-level code (configurations/default.nix) and handed to
# every module as the `xlib` argument via lib/mkSystem.nix, so modules read
# plain `xlib.*` values instead of `config.xlib.*` and nothing in xlib can be
# overridden per host — the host record is the only place to change it.
let
  # Every supported device type and its capabilities. Single source of truth:
  # replaces the old `lib.types.enum` in modules/options.nix and the
  # hand-written type lists in modules/default.nix and home/home.nix.
  devices = {
    minimal = {
      desktop = false;
      headless = false;
    };
    primary = {
      desktop = true;
      headless = false;
    };
    secondary = {
      desktop = true;
      headless = false;
    };
    server = {
      desktop = false;
      headless = true;
    };
    vds = {
      desktop = false;
      headless = true;
    };
    wsl = {
      desktop = false;
      headless = true;
    };
    termux = {
      desktop = false;
      headless = true;
    };
  };

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

  helpers = {
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
  };

  # Well-known paths. Everything derives from `username`, which is why the
  # whole set can be computed outside the module system.
  mkDirs =
    username:
    let
      user-home = "/home/${username}";
      wsl-home = "/mnt/c/Users/${username}";
      server-home = "${user-home}/External";
      services-mnt-folder = "/mnt/services";
    in
    {
      inherit
        user-home
        wsl-home
        server-home
        services-mnt-folder
        ;

      user-storage = "${user-home}/Storage";
      wsl-storage = "${wsl-home}/Storage";
      server-credentials = "${server-home}/Credentials/server";
      storage = "${server-home}/Storage";
      calibre-library = "${server-home}/Books-Library";
      services-folder = "${server-home}/Services";
      services-nodes-folder = "${services-mnt-folder}/nodes";
      postgresql-folder = "${services-mnt-folder}/postgresql";
      music-library = "${user-home}/Music";

      archive-drive = "/mnt/archive";
      lamet-drive = "/mnt/lamet";
      mobile-drive = "/mnt/mobile";
      therima-drive = "/mnt/therima";
      vetymae-drive = "/mnt/vetymae";
      soptur-drive = "/mnt/soptur";
    };

  mkXlib =
    {
      hostname,
      type,
      username ? "oqyude",
    }:
    let
      # Unknown device type fails here, at flake level, with the valid list.
      capabilities = devices.${type} or (throw "xlib: unknown device type '${type}', expected one of ${lib.concatStringsSep ", " (builtins.attrNames devices)}");
    in
    {
      device = {
        inherit
          hostname
          type
          username
          ;
      };
      isDesktop = capabilities.desktop;
      isHeadless = capabilities.headless;
      dirs = mkDirs username;
      inherit helpers;
    };
in
{
  inherit
    devices
    helpers
    mkDirs
    mkXlib
    ;
}
