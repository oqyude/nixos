{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "localhost:10000";
      database.createLocally = true;
      home = "/mnt/nextcloud";
      config = {
        dbtype = "mysql";
        dbuser = "nextcloud";
        #dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "oqyude";
        adminpassFile = "${inputs.zeroq.dirs.server-credentials}/nextcloud/admin-pass.txt";
      };
      settings = {
        appstoreEnable = false;
        log_type = "file";
        trusted_domains = [
          "nextcloud.zeroq.ru"
          #"100.64.0.0"
          #"192.168.1.18"
          #"localhost"
        ];
      };
      extraAppsEnable = true;
      extraApps = {
        inherit (pkgs.nextcloud30Packages.apps)
          bookmarks
          calendar
          contacts
          cookbook
          cospend
          deck
          end_to_end_encryption
          forms
          gpoddersync
          groupfolders
          impersonate
          integration_paperless
          mail
          maps
          memories
          music
          notes
          notify_push
          onlyoffice
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
    device = "${inputs.zeroq.dirs.nextcloud-folder}";
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
