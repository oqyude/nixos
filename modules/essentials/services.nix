{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    tailscale.enable = config.xlib.device.type != "wsl"; # true, if not wsl
  };
  systemd = {
    services.rsync-archive = lib.mkIf (config.xlib.device.type == "server") {
      description = "Backup data using rsync";
      after = [ "network.target" ];
      requisite = [ "mnt-archive.mount" ]; # hard-code
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = ''
          ${pkgs.rsync}/bin/rsync -rtv --delete ${config.xlib.dirs.immich-folder}/ ${config.xlib.dirs.archive-drive}/Services/immich/
          ${pkgs.rsync}/bin/rsync -rtv --delete ${config.xlib.dirs.nextcloud-folder}/ ${config.xlib.dirs.archive-drive}/Services/nextcloud/
        '';
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };
    timers.rsync-archive = lib.mkIf (config.xlib.device.type == "server") {
      description = "Run rsync backup weekly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        Unit = "rsync-archive.service";
      };
    };
  };
}
