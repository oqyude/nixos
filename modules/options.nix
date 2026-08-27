{
  config,
  lib,
  ...
}:
let
  # Option factory for the xlib.dirs namespace
  mkDir =
    default: description:
    lib.mkOption {
      type = lib.types.str;
      inherit default description;
    };

  helpers = import ../lib/xlib.nix { inherit lib; };
in
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
            "termux"
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
      ssh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable SSH server with the standard config.";
        };
      };
      dirs = {
        user-home = mkDir "/home/${config.xlib.device.username}" "User home directory.";
        user-storage = mkDir "${config.xlib.dirs.user-home}/Storage" "User storage directory.";
        archive-drive = mkDir "/mnt/archive" "Archive drive mount point.";
        lamet-drive = mkDir "/mnt/lamet" "Lamet drive mount point.";
        mobile-drive = mkDir "/mnt/mobile" "Mobile drive mount point.";
        therima-drive = mkDir "/mnt/therima" "Therima drive mount point.";
        vetymae-drive = mkDir "/mnt/vetymae" "Vetymae drive mount point.";
        soptur-drive = mkDir "/mnt/soptur" "Soptur drive mount point.";
        wsl-home = mkDir "/mnt/c/Users/${config.xlib.device.username}" "WSL home directory.";
        wsl-storage = mkDir "${config.xlib.dirs.wsl-home}/Storage" "WSL storage directory.";
        server-home = mkDir "/home/${config.xlib.device.username}/External" "Server home directory.";
        server-credentials = mkDir "${config.xlib.dirs.server-home}/Credentials/server" "Server credentials directory.";
        storage = mkDir "${config.xlib.dirs.server-home}/Storage" "General storage directory.";
        calibre-library = mkDir "${config.xlib.dirs.server-home}/Books-Library" "Calibre library directory.";
        music-library = mkDir "${config.xlib.dirs.user-home}/Music" "Music library directory.";
        services-folder = mkDir "${config.xlib.dirs.server-home}/Services" "All services folder.";
        services-mnt-folder = mkDir "/mnt/services" "All services folder.";
        services-nodes-folder = mkDir "${config.xlib.dirs.services-mnt-folder}/nodes" "All nodes folder.";
        postgresql-folder = mkDir "${config.xlib.dirs.services-mnt-folder}/postgresql" "PostgreSQL service folder.";
      };
      helpers = lib.mkOption {
        type = lib.types.anything;
        default = helpers;
        description = "Shared helper functions (see lib/xlib.nix).";
      };
      services."3x-ui" = {
        # Domain whose Let's Encrypt cert (at /var/lib/acme/<domain>/)
        # gets mounted read-only into the 3x-ui container so the panel
        # can terminate TLS itself. Set null if 3x-ui serves plain HTTP
        # and TLS is terminated by an upstream nginx.
        certDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "pubray1.zeroq.su";
          description = ''
            Domain whose LE cert should be mounted into the 3x-ui
            container at /root/cert/fullchain.pem and key.pem.
          '';
        };
        # Publish host:15380 → container:443. Only nodes that host an
        # Xray REALITY inbound on container:443 need this (so nginx
        # stream can forward TLS to Xray via 127.0.0.1:15380 while Xray
        # itself sees incoming connections on its configured port 443).
        # Set false on nodes that only run the 3x-ui panel.
        reality443Forwarding = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            When true, publish host:15380 → container:443 so Xray
            inside the container can serve REALITY on its real
            configured port 443 (nginx stream forwards 443 → 15380).
          '';
        };
      };
    };
  };
}
