{
  config,
  xlib,
  inputs,
  ...
}:
let
  work = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/e6f23dc08d3624daab7094b701aa3954923c6bbb.tar.gz";
  }) { };
  # myPkg = work.calibre-web;
in
{
  # services.calibre-server.package = stable.calibre;
  services.calibre-web = {
    enable = true;
    package = work.calibre-web;
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
