{
  config,
  xlib,
  inputs,
  ...
}:
{
  services.syncthing = {
    enable = true;
    # package = master.syncthing;
    systemService = true;
    guiAddress = "0.0.0.0:8384";
    configDir = "${xlib.dirs.storage}/persist/Syncthing/${xlib.device.hostname}";
    dataDir = "${xlib.dirs.server-home}";
    group = "users";
    user = "${xlib.device.username}";
  };
}
