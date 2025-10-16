{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
let
  work = import inputs.nixpkgs-stable {
    system = "x86_64-linux";
    config.allowUnfree = true;
    config.allowUnfreePredicate = true;
  };
in
{
  services = {
    nextcloud-whiteboard-server = {
      enable = true;
      settings = {
        NEXTCLOUD_URL = "http://nextcloud.local";
      };
      secrets = [ "${inputs.zeroq-credentials}/services/nextcloud/jwt-secret.txt" ];
    };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud32;
      hostName = "nextcloud.local";
      database.createLocally = true;
      home = "${xlib.dirs.services-mnt-folder}/nextcloud";
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
        ];
        trusted_proxies = [
          "100.64.1.0"
        ];
        overwriteprotocol = "https";
      };
      extraAppsEnable = true;
      appstoreEnable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps) # (config.services.nextcloud.package.packages.apps)
          # onlyoffice
          bookmarks
          calendar
          collectives
          contacts
          cookbook
          cospend
          dav_push
          deck
          files_retention
          forms
          gpoddersync
          groupfolders
          impersonate
          integration_paperless
          mail
          memories
          music
          news
          nextpod
          notes
          notify_push
          phonetrack
          polls
          previewgenerator
          repod
          richdocuments
          sociallogin
          spreed
          tables
          user_oidc
          user_saml
          whiteboard
          ;
        inherit (pkgs.nextcloud31Packages.apps)
          # end_to_end_encryption
          maps
          tasks
          ;
      };
    };
    collabora-online = {
      enable = true;
      port = 9980;
      settings = {
        server_name = "office.zeroq.ru";
        ssl = {
          enable = false;
          termination = true;
          ssl_verification = false;
        };
        net = {
          listen = "0.0.0.0";
          post_allow.host = [
            "0.0.0.0"
          ];
        };
        storage.wopi = {
          "@allow" = true;
          host = [
            "0.0.0.0/0"
          ];
        };
      };
    };
    onlyoffice = {
      enable = false;
      hostname = "0.0.0.0";
      jwtSecretFile = "${inputs.zeroq-credentials}/services/onlyoffice/jwt.txt";
    };
  };

  # fonts.packages = [ work.corefonts ];

  # networking.hosts = {
  # };

  systemd.services.nextcloud-config-collabora =
    let
      inherit (config.services.nextcloud) occ;
      wopi_url = "http://localhost:${toString config.services.collabora-online.port}";
      public_wopi_url = "https://office.zeroq.ru";
      wopi_allowlist = lib.concatStringsSep "," [
        "0.0.0.0/0"
      ];
    in
    {
      wantedBy = [ "multi-user.target" ];
      after = [
        "nextcloud-setup.service"
        "coolwsd.service"
      ];
      requires = [ "coolwsd.service" ];
      script = ''
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
        ${occ}/bin/nextcloud-occ richdocuments:setup
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };

  fileSystems."${config.services.nextcloud.home}" = {
    device = "${xlib.dirs.services-folder}/nextcloud";
    options = [
      "bind"
      "nofail"
    ];
  };

  systemd.tmpfiles.rules = [
    "z ${config.services.nextcloud.home} 0750 nextcloud nextcloud -"
  ];

  environment.systemPackages = [
    pkgs.nc4nix # Packaging helper for Nextcloud apps
  ];
}
