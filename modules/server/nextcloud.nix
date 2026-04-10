{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
    # config.allowUnfree = true;
    # config.allowUnfreePredicate = true;
  };
in
{
  services = {
    nextcloud-whiteboard-server = {
      enable = true;
      settings = {
        NEXTCLOUD_URL = "http://nextcloud-private.local";
      };
      secrets = [ config.sops.secrets.nextcloud-whiteboard-jwt.path ];
    };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      hostName = "nextcloud-private.local";
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
        dbname = "nextcloud";
        adminuser = "oqyude";
        adminpassFile = config.sops.secrets.nextcloud-adminpass.path;
      };
      settings = {
        log_type = "file";
        trusted_domains = [
          "nextcloud.zeroq.su"
          "office.zeroq.su"
          "100.64.0.0"
          "192.168.1.20"
          "localhost"
          "nextcloud.local"
          "nextcloud-private.local"
        ];
        trusted_proxies = [
          "100.64.1.0"
          "109.248.161.5"
        ];
        overwriteprotocol = "https"; # maybe no
      };
      extraAppsEnable = true;
      appstoreEnable = false;
      notify_push = {
        enable = false;
        bendDomainToLocalhost = true;
      };
      # phpPackage = pkgs.php85;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          # gpoddersync
          # integration_paperless
          # memories
          # nextpod
          onlyoffice
          # phonetrack
          # repod
          # sociallogin
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
          groupfolders
          impersonate
          mail
          music
          tasks
          # news
          notes
          # notify_push
          polls
          previewgenerator
          #           richdocuments
          spreed
          tables
          user_oidc
          user_saml
          whiteboard
          ;
        # inherit (pkgs.nextcloud31Packages.apps)
        #   # end_to_end_encryption
        #   # maps
        #   tasks
        #   ;
      };
    };
    collabora-online = {
      enable = false;
      port = 9980;
      # package = master.collabora-online;
      settings = {
        server_name = "office.zeroq.su";
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
      enable = true;
      hostname = "0.0.0.0";
      wopi = true;
      jwtSecretFile = config.sops.secrets.onlyoffice-jwt.path;
      securityNonceFile = config.sops.secrets.onlyoffice-nonce.path;
    };
  };

  # fonts.packages = [ work.corefonts ];

  #   networking.hosts = {
  #     "localhost" = [ "nextcloud-private.local" ];
  #   };

  #   systemd.services.nextcloud-config-collabora =
  #     let
  #       inherit (config.services.nextcloud) occ;
  #       wopi_url = "http://localhost:${toString config.services.collabora-online.port}";
  #       public_wopi_url = "https://office.zeroq.su";
  #       wopi_allowlist = lib.concatStringsSep "," [
  #         "0.0.0.0/0"
  #       ];
  #     in
  #     {
  #       wantedBy = [ "multi-user.target" ];
  #       after = [
  #         "nextcloud-setup.service"
  #         "coolwsd.service"
  #       ];
  #       requires = [ "coolwsd.service" ];
  #       script = ''
  #         ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
  #         ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
  #         ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
  #         ${occ}/bin/nextcloud-occ richdocuments:setup
  #       '';
  #       serviceConfig = {
  #         Type = "oneshot";
  #       };
  #     };

  systemd.tmpfiles.rules = [
    "z ${config.services.nextcloud.home} 0750 nextcloud nextcloud -"
  ];

  environment.systemPackages = [
    pkgs.nc4nix # Packaging helper for Nextcloud apps
  ];

  sops.secrets = {
    nextcloud-adminpass = {
      format = "yaml";
      key = "adminpass";
      sopsFile = ./secrets/nextcloud.yaml;
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0650";
    };
    nextcloud-whiteboard-jwt = {
      format = "yaml";
      key = "whiteboard-jwt";
      sopsFile = ./secrets/nextcloud.yaml;
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0650";
    };
    onlyoffice-nonce = {
      format = "yaml";
      key = "nonce";
      sopsFile = ./secrets/onlyoffice.yaml;
      owner = "onlyoffice";
      group = "onlyoffice";
      mode = "0650";
    };
    onlyoffice-jwt = {
      format = "yaml";
      key = "jwt";
      sopsFile = ./secrets/onlyoffice.yaml;
      owner = "onlyoffice";
      group = "onlyoffice";
      mode = "0650";
    };
  };
}
