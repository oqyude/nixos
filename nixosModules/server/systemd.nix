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
      # Make copy of files
      description = "Backup data using rsync";
      #after = [ ];
      requisite = [ "mnt-archive.mount" ]; # hard-code
      script = ''
        
                ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.services-folder}/immich/ ${xlib.dirs.archive-drive}/Services/immich/
                ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.services-folder}/nextcloud/ ${xlib.dirs.archive-drive}/Services/nextcloud/
                ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.services-folder}/node-red/ ${xlib.dirs.archive-drive}/Services/node-red/
                ${pkgs.rsync}/bin/rsync -rtv --delete ${xlib.dirs.services-folder}/uptime-kuma/ ${xlib.dirs.archive-drive}/Services/node-red/
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
