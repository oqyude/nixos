{
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
          default = "/home/${config.xlib.device.username}";
          description = "User home directory.";
        };
        user-storage = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.user-home}/Storage";
          description = "User storage directory.";
        };
        archive-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/archive";
          description = "Archive drive mount point.";
        };
        therima-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/therima";
          description = "Therima drive mount point.";
        };
        vetymae-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/vetymae";
          description = "Vetymae drive mount point.";
        };
        wsl-home = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/c/Users/${config.xlib.device.username}";
          description = "WSL home directory.";
        };
        wsl-storage = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.wsl-home}/Storage";
          description = "WSL storage directory.";
        };
        server-home = lib.mkOption {
          type = lib.types.str;
          default = "/home/${config.xlib.device.username}/External";
          description = "Server home directory.";
        };
        server-credentials = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Credentials/server";
          description = "Server credentials directory.";
        };
        storage = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Storage";
          description = "General storage directory.";
        };
        calibre-library = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Books-Library";
          description = "Calibre library directory.";
        };
        music-library = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.user-home}/Music";
          description = "Music library directory.";
        };
        immich-folder = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Services/immich";
          description = "Immich service folder.";
        };
        nextcloud-folder = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Services/nextcloud";
          description = "Nextcloud service folder.";
        };
        postgresql-folder = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Services/postgresql";
          description = "PostgreSQL service folder.";
        };
      };
    };
  };
}
