{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  systemd = {
    services.rsync-archive = {
      # Archivesta
      # Make copy of files
      description = "Backup data using rsync";
      #after = [ ];
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
    timers.rsync-archive = {
      description = "Run rsync backup weekly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "rsync-archive.service";
      };
    };
  };
}
