{
  config,
  inputs,
  pkgs,
  xlib,
  ...
}:
let
  stable = import inputs.nixpkgs-previous {
    system = "x86_64-linux";
  };
in
{
  services = {
    calibre-web = {
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
    # calibre-server = {
    #   enable = true;
    #   port = 8091;
    #   host = "0.0.0.0";
    #   openFirewall = true;
    #   user = "calibre-web";
    #   group = "calibre-web";
    #   libraries = [
    #     "/var/lib/calibre-server"
    #   ];
    # };
  };

  systemd.tmpfiles.rules = [
    "d ${xlib.dirs.services-mnt-folder}/calibre-web 0755 calibre-web calibre-web -"
    "d ${xlib.dirs.services-mnt-folder}/calibre-web-library 0755 calibre-web calibre-web -"
  ];

  fileSystems = {
    "/var/lib/calibre-web" = {
      device = "${xlib.dirs.services-mnt-folder}/calibre-web";
      fsType = "none";
      options = [
        "bind"
        "nofail"
      ];
    };
  };
}
