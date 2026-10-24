{
  config,
  xlib,
  inputs,
  ...
}:
{
  services.syncthing = {
    enable = true;
    systemService = true;
    guiAddress = "0.0.0.0:8384";
    configDir = "${xlib.dirs.storage}/persist/Syncthing/${xlib.device.hostname}";
    dataDir = "${xlib.dirs.server-home}";
    group = "users";
    user = "${xlib.device.username}";
  };

  # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
  # directive and is ignored by systemd in `[Service]` (T4/R1.2).
  systemd.services.syncthing.unitConfig = xlib.helpers.mkStorageGuard xlib;
}
