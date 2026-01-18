{
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
            "secondary"
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
      users.new =  lib.mkOption {
        type = lib.types.str;
        default = "snity";
        description = "Username for guest.";
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
        lamet-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/lamet";
          description = "Lamet drive mount point.";
        };
        mobile-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/mobile";
          description = "Mobile drive mount point.";
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
        soptur-drive = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/soptur";
          description = "Soptur drive mount point.";
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
        services-folder = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.server-home}/Services";
          description = "All services folder.";
        };
        services-mnt-folder = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/services";
          description = "All services folder.";
        };
        postgresql-folder = lib.mkOption {
          type = lib.types.str;
          default = "${config.xlib.dirs.services-mnt-folder}/postgresql";
          description = "PostgreSQL service folder.";
        };
      };
    };
  };
}
