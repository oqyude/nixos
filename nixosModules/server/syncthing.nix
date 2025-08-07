{
  config,
  ...
}:
{
  services.syncthing = {
    enable = true;
    systemService = true;
    guiAddress = "0.0.0.0:8384";
    configDir = "${config.xlib.dirs.storage}/Syncthing/${config.xlib.device.hostname}";
    dataDir = "${config.xlib.dirs.server-home}";
    group = "users";
    user = "${config.xlib.device.username}";
  };
}
