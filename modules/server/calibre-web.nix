{
  config,
  xlib,
  inputs,
  ...
}:
# let
#   work = import inputs.nixpkgs-master { system = "x86_64-linux"; };
# in
{
  # services.calibre-server.package = stable.calibre;
  services.calibre-web = {
    enable = true;
    # package = work.calibre-web;
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
