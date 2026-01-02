{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  systemd = {
    services = {
      rsync-archivesta = {
        # Archivesta
        description = "Backup data using rsync";
        requisite = [ "mnt-archive.mount" ]; # hard-code
        script = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.services-folder}/ ${xlib.dirs.archive-drive}/Services/
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
      rsync-archivesta-lite = {
        # Archivesta Lite
        description = "Backup data using rsync";
        requisite = [ "mnt-mobile.mount" ]; # hard-code
        script = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.server-home}/Music/ ${xlib.dirs.mobile-drive}/Music/
          ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.server-home}/Hosts/epral/Neo Backup/ ${xlib.dirs.mobile-drive}/Neo Backup/
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
    };
    timers = {
      rsync-archivesta = {
        description = "Run rsync backup daily";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "rsync-archive.service";
        };
      };
      rsync-archivesta-lite = {
        description = "Run rsync backup weekly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          Unit = "rsync-archive.service";
        };
      };
    };
  };
}
