{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    # nextcloud-whiteboard-server = {
    #   enable = true;
    #   settings = {
    #     NEXTCLOUD_URL = "http://localhost:10000";
    #   };
    #   secrets = [ "${inputs.zeroq-credentials}/services/nextcloud/jwt-secret.txt" ];
    # };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "localhost:10000";
      database.createLocally = true;
      home = "/mnt/nextcloud";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        #dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "oqyude";
        adminpassFile = "${inputs.zeroq-credentials}/services/nextcloud/admin-pass.txt";
      };
      settings = {
        appstoreEnable = false;
        log_type = "file";
        trusted_domains = [
          "nextcloud.zeroq.ru"
          "100.64.0.0"
          "192.168.1.20"
          "localhost"
          "sapphira.latxa-platy.ts.net"
        ];
        overwriteprotocol = "https";
      };
      extraAppsEnable = true;
      extraApps = {
        inherit (pkgs.nextcloud31Packages.apps)
          deck
          end_to_end_encryption
          groupfolders
          impersonate
          onlyoffice
          bookmarks
          calendar
          contacts
          cookbook
          cospend
          forms
          gpoddersync
          integration_paperless
          mail
          maps
          memories
          music
          notes
          notify_push
          polls
          previewgenerator
          richdocuments
          spreed
          tasks
          user_oidc
          user_saml
          whiteboard
          ;
      };
    };
  };

  fileSystems."/mnt/nextcloud" = {
    device = "${config.xlib.dirs.nextcloud-folder}";
    options = [
      "bind"
      #"uid=1000"
      #"gid=1000"
      #"fmask=0007"
      #"dmask=0007"
      "nofail"
      "x-systemd.device-timeout=0"
    ];
  };

  systemd.tmpfiles.rules = [
    "z /mnt/nextcloud 0755 nextcloud nextcloud -"
  ];
}
