{
  config,
  pkgs,
  xlib,
  ...
}:
let
  storage = xlib.helpers.mkServiceStorage {
    name = "homebox";
    user = "homebox";
    group = "homebox";
  };
in
{
  services.homebox = {
    enable = true;
    settings = {
      HBOX_WEB_HOST = "0.0.0.0";
      HBOX_WEB_PORT = "7745";
      HBOX_STORAGE_CONN_STRING = "file://${storage.target}";
      HBOX_STORAGE_PREFIX_PATH = "data";
      HBOX_DATABASE_DRIVER = "sqlite3";
      HBOX_DATABASE_SQLITE_PATH = "${storage.target}/data/homebox.db?_pragma=busy_timeout=999&_pragma=journal_mode=WAL&_fk=1";
      HBOX_OPTIONS_ALLOW_REGISTRATION = "true";
      HBOX_OPTIONS_GITHUB_RELEASE_CHECK = "false";
      HBOX_MODE = "production";
      HOME = "${storage.target}";
      TMPDIR = "${storage.target}/tmp";
    };
  };

  systemd = storage.systemd;
}
