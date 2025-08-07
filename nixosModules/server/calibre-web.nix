{
  config,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    group = "users";
    user = "${config.xlib.device.username}";
    options = {
      calibreLibrary = "${config.xlib.dirs.calibre-library}";
      enableBookUploading = true;
      enableKepubify = false;
    };
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    openFirewall = true;
  };
}
