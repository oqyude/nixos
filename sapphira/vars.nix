rec {
  this-admin = "oqyude";
  dirs = rec {
    user-home = "/home/${this-admin}";
    home = "/mnt/server";
    sync = "${home}/Sync";
    storage = "${home}/Storage";
    calibre-library = "${home}/Library";
    nextcloud-source = "${home}/Nextcloud";
    nextcloud-target = "/var/lib/nextcloud";
    credentials-source-server = "${home}/Credentials/.server";
    credentials-target = "/var/lib/credentials";
  };
}
