{
  config,
  ...
}:
{
  services = {
    tailscale.enable = config.xlib.device.type != "wsl"; # true, if not wsl
  systemd = {
    services.rsync-archive = lib.mkIf (config.xlib.device.type == "server") {
      description = "Backup data using rsync";
      after = [ "network.target" ];
      requiresMountsFor = [ config.xlib.dirs.archive-drive ];
      serviceConfig = {
        Type = "oneshot";
        #ExecStartPre = "/bin/sh -c 'if ! mountpoint -q ${config.xlib.dirs.archive-drive}; then exit 1; fi'";
        ExecStart = "${pkgs.rsync}/bin/rsync -av --delete ${config.xlib.dirs.immich-folder} ${config.xlib.dirs.archive-drive}/Services/immich";
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
      };
    };
  };
  };
}
