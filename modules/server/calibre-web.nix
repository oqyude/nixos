{
  config,
  xlib,
  inputs,
  ...
}:
let
  stable = import inputs.nixpkgs-calibre {
    system = "x86_64-linux";
  }; # temp
in
{
  services.calibre-server.package = stable.calibre;
  services.calibre-web = {
    enable = true;
    package = stable.calibre-web;
    group = "users";
    user = "${xlib.device.username}";
    options = {
      calibreLibrary = "${xlib.dirs.calibre-library}";
      enableBookUploading = true;
      enableKepubify = true;
      enableBookConversion = true;
    };
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    openFirewall = true;
  };
}
