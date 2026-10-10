{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    rsync = {
      enable = true;
      jobs = {
        archivesta-mobile-music = {
          user = "root";
          group = "root";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          sources = [
            "${xlib.dirs.server-home}/Music/"
          ];
          destination = "${xlib.dirs.mobile-drive}/Music/";
          settings = {
            archive = true;
            delete = true;
            mkpath = true;
            verbose = true;
          };
        };
        archivesta-mobile-neo = {
          user = "root";
          group = "root";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          sources = [
            "${xlib.dirs.server-home}/Hosts/epral/Neo Backup/"
          ];
          destination = "${xlib.dirs.mobile-drive}/Neo Backup/";
          settings = {
            archive = true;
            delete = true;
            mkpath = true;
            verbose = true;
          };
        };
        archivesta-services = {
          user = "root";
          group = "root";
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
          sources = [
            "${xlib.dirs.services-folder}/"
          ];
          destination = "${xlib.dirs.archive-drive}/Services/";
          settings = {
            archive = true;
            delete = true;
            mkpath = true;
            verbose = true;
          };
        };
      };
    };
  };
}
