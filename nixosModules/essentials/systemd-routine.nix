{
  config,
  xlib,
  ...
}:
{
  systemd = {
    services.nixos-auto-rebuild = {
      description = "Auto rebuild NixOS config";
      serviceConfig = {
        Type = "oneshot";
        User = "${xlib.device.username}";
        WorkingDirectory = "/etc/nixos";
        ExecStart = "gp-ns";
      };
    };
    timers.nixos-auto-rebuild = {
      description = "Run NixOS auto rebuild at 4am daily";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
      };
    };
  };
}
