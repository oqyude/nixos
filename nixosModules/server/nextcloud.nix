{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
{
  services = {
    nextcloud-whiteboard-server = {
      enable = false;
      settings = {
        NEXTCLOUD_URL = "http://localhost:10000";
      };
      secrets = [ "${inputs.zeroq-credentials}/services/nextcloud/jwt-secret.txt" ];
    };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "localhost:10000";
      database.createLocally = true;
      home = "/mnt/nextcloud";
      configureRedis = true;
      caching = {
        redis = true;
        memcached = true;
      };
      maxUploadSize = "5G";
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        #dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "oqyude";
        adminpassFile = "${inputs.zeroq-credentials}/services/nextcloud/admin-pass.txt";
      };
      settings = {
        log_type = "file";
        trusted_domains = [
          "nextcloud.zeroq.ru"
          "100.64.0.0"
          "192.168.1.20"
          "localhost"
          "sapphira.latxa-platy.ts.net"
        ];
        trusted_proxies = [
          "100.64.1.0"
        ];
        overwriteprotocol = "https";
      };
      extraAppsEnable = true;
      appstoreEnable = true;
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
    # collabora-online = {
    #   enable = false;
    #   port = 9980;
    #   settings = {
    #     # Rely on reverse proxy for SSL
    #     server_name = "collabora.zeroq.ru";
    #     ssl = {
    #       enable = false;
    #       termination = true;
    #       ssl_verification = false;
    #     };
    #     net = {
    #       listen = "loopback";
    #       post_allow.host = [
    #         "localhost"
    #         "100.64.0.0"
    #       ]; # "::1"
    #     };
    #     storage.wopi = {
    #       "@allow" = true;
    #       host = [ "nextcloud.zeroq.ru" ];
    #     };
    #   };
    # };
    onlyoffice = {
      enable = false;
      hostname = "127.0.0.1";
    };
    #rabbitmq.enable = false;
  };

  networking.hosts = {
    "127.0.0.1" = [
      "nextcloud.zeroq.ru"
      "office.zeroq.com"
      "collabora.zeroq.ru"
    ];
    "::1" = [
      "nextcloud.zeroq.ru"
      "collabora.zeroq.ru"
      "office.zeroq.com"
    ];
  };

  # systemd.services.nextcloud-config-collabora =
  #   let
  #     inherit (config.services.nextcloud) occ;
  #     wopi_url = "http://[::1]:${toString config.services.collabora-online.port}";
  #     public_wopi_url = "https://collabora.zeroq.ru";
  #     wopi_allowlist = lib.concatStringsSep "," [
  #       "127.0.0.1"
  #       "::1"
  #     ];
  #   in
  #   {
  #     wantedBy = [ "multi-user.target" ];
  #     after = [
  #       "nextcloud-setup.service"
  #       "coolwsd.service"
  #     ];
  #     requires = [ "coolwsd.service" ];
  #     script = ''
  #       ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
  #       ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
  #       ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
  #       ${occ}/bin/nextcloud-occ richdocuments:setup
  #     '';
  #     serviceConfig = {
  #       Type = "oneshot";
  #     };
  #   };

  fileSystems."/mnt/nextcloud" = {
    device = "${xlib.dirs.nextcloud-folder}";
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

  environment.systemPackages = [
    pkgs.nc4nix # Packaging helper for Nextcloud apps
  ];
}
