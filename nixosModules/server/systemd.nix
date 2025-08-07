{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd = {
    services.rsync-archive = { # Make copy of files
      description = "Backup data using rsync";
      #after = [ ];
      requisite = [ "mnt-archive.mount" ]; # hard-code
      script = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete ${config.xlib.dirs.immich-folder}/ ${config.xlib.dirs.archive-drive}/Services/immich/
          ${pkgs.rsync}/bin/rsync -rtv --delete ${config.xlib.dirs.nextcloud-folder}/ ${config.xlib.dirs.archive-drive}/Services/nextcloud/
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        # ExecStart = ''
        # '';
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
