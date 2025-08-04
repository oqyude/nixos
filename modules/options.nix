{
  inputs,
  config,
  lib,
  ...
}:
{
  options = {
    xlib = {
      device = {
        type = lib.mkOption {
          type = lib.types.enum [
            "minimal"
            "primary"
            "server"
            "vds"
            "wsl"
          ];
          default = "minimal";
          description = "Type of device for this host.";
        };
        username = lib.mkOption {
          type = lib.types.str;
          default = "oqyude";
          description = "Username for host.";
        };
        hostname = lib.mkOption {
          type = lib.types.str;
          default = "nixos";
          description = "Hostname...";
        };
      };
      dirs = {
        user-home = lib.mkOption {
          type = lib.types.str;
          description = "User home directory.";
        };
        user-storage = lib.mkOption {
          type = lib.types.str;
          description = "User storage directory.";
        };
        therima-drive = lib.mkOption {
          type = lib.types.str;
          description = "Therima drive mount point.";
        };
        vetymae-drive = lib.mkOption {
          type = lib.types.str;
          description = "Vetymae drive mount point.";
        };
        wsl-home = lib.mkOption {
          type = lib.types.str;
          description = "WSL home directory.";
        };
        wsl-storage = lib.mkOption {
          type = lib.types.str;
          description = "WSL storage directory.";
        };
        server-home = lib.mkOption {
          type = lib.types.str;
          description = "Server home directory.";
        };
        server-credentials = lib.mkOption {
          type = lib.types.str;
          description = "Server credentials directory.";
        };
        storage = lib.mkOption {
          type = lib.types.str;
          description = "General storage directory.";
        };
        calibre-library = lib.mkOption {
          type = lib.types.str;
          description = "Calibre library directory.";
        };
        music-library = lib.mkOption {
          type = lib.types.str;
          description = "Music library directory.";
        };
        immich-folder = lib.mkOption {
          type = lib.types.str;
          description = "Immich service folder.";
        };
        nextcloud-folder = lib.mkOption {
          type = lib.types.str;
          description = "Nextcloud service folder.";
        };
        postgresql-folder = lib.mkOption {
          type = lib.types.str;
          description = "PostgreSQL service folder.";
        };
      };
    };
  };
  config = {
    xlib.dirs = {
      user-home = "/home/${config.xlib.device.username}";
      user-storage = "${config.xlib.dirs.user-home}/Storage";
      therima-drive = "/mnt/therima";
      vetymae-drive = "/mnt/vetymae";
      wsl-home = "/mnt/c/Users/${config.xlib.device.username}";
      wsl-storage = "${config.xlib.dirs.wsl-home}/Storage";
      server-home = "/home/${config.xlib.device.username}/External";
      server-credentials = "${config.xlib.dirs.server-home}/Credentials/server";
      storage = "${config.xlib.dirs.server-home}/Storage";
      calibre-library = "${config.xlib.dirs.server-home}/Books-Library";
      music-library = "${config.xlib.dirs.user-home}/Music";
      immich-folder = "${config.xlib.dirs.server-home}/Services/immich";
      nextcloud-folder = "${config.xlib.dirs.server-home}/Services/nextcloud";
      postgresql-folder = "${config.xlib.dirs.server-home}/Services/postgresql";
    };
  };
}
