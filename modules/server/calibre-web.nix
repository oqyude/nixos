{
  config,
  xlib,
  inputs,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    group = "users";
    user = "${xlib.device.username}";
    options = {
      calibreLibrary = "${xlib.dirs.calibre-library}";
      enableBookUploading = true;
      enableKepubify = true;
      enableBookConversion = false;
    };
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    openFirewall = true;
  };
}
