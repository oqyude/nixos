{
  config,
  pkgs,
  xlib,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/homebox";
  targetDir = "/var/lib/homebox";
in
{
  services.homebox = {
    enable = true;
    settings = {
      HBOX_WEB_HOST = "0.0.0.0";
      HBOX_WEB_PORT = "7745";
      HBOX_STORAGE_CONN_STRING = "file://${targetDir}";
      HBOX_STORAGE_PREFIX_PATH = "data";
      HBOX_DATABASE_DRIVER = "sqlite3";
      HBOX_DATABASE_SQLITE_PATH = "${targetDir}/data/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1";
      HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
      HBOX_OPTIONS_GITHUB_RELEASE_CHECK = "false";
      HBOX_MODE = "production";
      HOME = "${targetDir}";
      TMPDIR = "${targetDir}/tmp";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d ${sourceDir} 0755 homebox homebox -"
      "z ${sourceDir} 0755 homebox homebox -"
    ];
    mounts = [
      {
        enable = true;
        options = "bind,x-systemd.automount,nofail";
        requires = [ "local-fs.target" ];
        type = "none";
        wantedBy = [ "multi-user.target" ];
        what = "${sourceDir}";
        where = "${targetDir}";
      }
    ];
  };
}
