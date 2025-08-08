{
  config,
  xlib,
  ...
}:
{
  services.syncthing = {
    enable = true;
    systemService = true;
    guiAddress = "0.0.0.0:8384";
    configDir = "${xlib.dirs.storage}/Syncthing/${xlib.device.hostname}";
    dataDir = "${xlib.dirs.server-home}";
    group = "users";
    user = "${xlib.device.username}";
  };
}
