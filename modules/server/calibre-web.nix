{
  config,
  inputs,
  pkgs,
  xlib,
  ...
}:
let
  # stable = import inputs.nixpkgs-previous {
  #   system = "x86_64-linux";
  # };
  libraryDir = "${xlib.dirs.services-mnt-folder}/calibre-web-library";
  sourceDir = "${xlib.dirs.services-mnt-folder}/calibre-web";
  targetDir = "/var/lib/calibre-web";
in
{
  services = {
    calibre-web = {
      # package = stable.calibre-web;
      enable = true;
      # dataDir = "${xlib.dirs.services-mnt-folder}/calibre-web";
      options = {
        calibreLibrary = "${libraryDir}";
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

  systemd.tmpfiles.rules =
    xlib.helpers.mkTmpDirs {
      dir = libraryDir;
      mode = "0755";
      user = "calibre-web";
      group = "calibre-web";
      types = [
        "d"
        "Z"
      ];
    }
    ++ xlib.helpers.mkTmpDirs {
      dir = sourceDir;
      mode = "0755";
      user = "calibre-web";
      group = "calibre-web";
      types = [
        "d"
        "Z"
      ];
    };

  fileSystems = xlib.helpers.mkBindMount {
    what = sourceDir;
    where = targetDir;
  };
}
