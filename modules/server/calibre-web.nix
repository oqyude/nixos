{
  config,
  xlib,
  inputs,
  ...
}:
let
  stable = import inputs.nixpkgs-beets {
    system = "x86_64-linux";
  };
in
{
  services.calibre-web = {
    package = stable.calibre-web;
    enable = true;
    # dataDir = "${xlib.dirs.services-mnt-folder}/calibre-web";
    options = {
      calibreLibrary = "${xlib.dirs.services-mnt-folder}/calibre-web-library";
      enableBookUploading = true;
      enableKepubify = true;
      enableBookConversion = false;
    };
    listen.ip = "0.0.0.0";
    listen.port = 8083;
    openFirewall = true;
  };  
  
  fileSystems."${config.services.calibre-web.dataDir}" = {
    device = "${xlib.dirs.services-mnt-folder}/calibre-web";
    options = [
      "bind"
      "nofail"
    ];
  };
}
