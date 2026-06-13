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
        unitConfig.RequiresMountsFor = [
          "${xlib.dirs.archive-drive}"
          "${xlib.dirs.server-home}"
          "${xlib.dirs.services-mnt-folder}"
        ];
        script = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete \
            ${xlib.dirs.services-mnt-folder}/ \
            ${xlib.dirs.archive-drive}/Services/
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          Nice = 10;
          CPUQuota = "5%";
          IOSchedulingClass = "idle";
        };
      };
      rsync-archivesta-lite = {
        # Archivesta Lite
        description = "Backup data using rsync";
        unitConfig.RequiresMountsFor = [
          "${xlib.dirs.server-home}"
          "${xlib.dirs.mobile-drive}"
        ];
        script = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete \
            ${xlib.dirs.server-home}/Music/ \
            ${xlib.dirs.mobile-drive}/Music/

          ${pkgs.rsync}/bin/rsync -rtv --delete \
            "${xlib.dirs.server-home}/Hosts/epral/Neo Backup/" \
            "${xlib.dirs.mobile-drive}/Neo Backup/"
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          Nice = 10;
          CPUQuota = "5%";
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
          Unit = "rsync-archivesta.service";
        };
      };
      rsync-archivesta-lite = {
        description = "Run rsync backup weekly";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          Unit = "rsync-archivesta-lite.service";
        };
      };
    };
  };
}
