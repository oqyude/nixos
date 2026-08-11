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
    };
  };
}
