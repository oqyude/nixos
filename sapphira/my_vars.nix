rec {
  this-host = "sapphira";
  this-admin = "oqyude";
  dirs = rec {
    user-home = "/home/${this-host}";
    home = "/mnt/server";
    structure = "${home}/Structure";
    sync = "${home}/Sync";
    shared = "${structure}/Shared";
    storage = "${shared}/Storage";
    programs = "${storage}/Programs";
    settings = "${storage}/Settings";
    calibre-library = "${home}/Library";
    nextcloud-source = "${home}/Nextcloud";
    nextcloud-target = "/var/lib/nextcloud";
    credentials-source-server = "${home}/Credentials/.server";
    credentials-target = "/var/lib/credentials";
  };
}
