{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  previous = import inputs.nixpkgs-master {
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
        NEXTCLOUD_URL = "https://nextcloud.home.arpa";
      };
      secrets = [ config.sops.secrets.nextcloud-whiteboard-jwt.path ];
    };
    nextcloud-spreed-signaling = {
      enable = false;
      hostName = "talk.private";
      backends.nextcloud = {
        urls = [
          "https://nextcloud.home.arpa"
          "https://nextcloud.zeroq.su"
        ];
        secretFile = config.sops.secrets.nextcloud-talk-secret.path;
      };
      settings = {
        http.listen = "127.0.0.1:8080";
        clients.internalsecretFile = config.sops.secrets.internal-secret.path;
        sessions = {
          hashkeyFile = config.sops.secrets.hashkey.path;
          blockkeyFile = config.sops.secrets.blockkey.path;
        };
        mcu = {
          type = "janus";
          url = "ws://127.0.0.1:8188";
        };
        turn = {
          secretFile = config.sops.secrets.turn-secret.path;
          apikeyFile = config.sops.secrets.turn-api-key.path;
          servers = [
            "turn:turn.home.arpa:3478?transport=udp"
            "turn:turn.home.arpa:3478?transport=tcp"
            # "turns:turn.home.arpa:5349?transport=tcp"
          ];
        };
      };
    };
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      hostName = "nextcloud.private";
      database.createLocally = true;
      home = "${xlib.dirs.services-mnt-folder}/nextcloud";
      configureRedis = true;
      https = true;
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
          "100.64.0.0"
          "192.168.1.20"
          "localhost"
          "nextcloud.private"
          "nextcloud.zeroq.su"
          "office.zeroq.su"
          "office.home.arpa"
          "nextcloud.home.arpa"
        ];
        trusted_proxies = [
          "100.64.1.0"
          "192.168.1.20"
          "109.248.161.5"
        ];
        overwriteprotocol = "https"; # maybe no
      };
      extraAppsEnable = true;
      appstoreEnable = false;
      notify_push = {
        enable = true;
        bendDomainToLocalhost = true;
        nextcloudUrl = "https://nextcloud.home.arpa";
      };
      # phpPackage = pkgs.php85;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          # richdocuments
          # gpoddersync
          # integration_paperless
          # memories
          # news
          # nextpod
          # notify_push
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
          notes
          onlyoffice
          polls
          previewgenerator
          spreed
          tables
          tasks
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
    # collabora-online = {
    #   enable = false;
    #   port = 9980;
    #   # package = master.collabora-online;
    #   settings = {
    #     server_name = "office.zeroq.su";
    #     ssl = {
    #       enable = false;
    #       termination = true;
    #       ssl_verification = false;
    #     };
    #     net = {
    #       listen = "0.0.0.0";
    #       post_allow.host = [
    #         "0.0.0.0"
    #       ];
    #     };
    #     storage.wopi = {
    #       "@allow" = true;
    #       host = [
    #         "0.0.0.0/0"
    #       ];
    #     };
    #   };
    # };
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
    nextcloud-talk-secret = {
      format = "yaml";
      key = "nextcloud-talk-secret";
      sopsFile = ./secrets/nextcloud.yaml;
      # owner = "nextcloud-spreed-signaling";
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
    internal-secret = {
      format = "yaml";
      key = "internal-secret";
      sopsFile = ./secrets/nextcloud.yaml;
      # owner = "nextcloud-spreed-signaling";
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
    hashkey = {
      format = "yaml";
      key = "hashkey";
      sopsFile = ./secrets/nextcloud.yaml;
      # owner = "nextcloud-spreed-signaling";
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
    blockkey = {
      format = "yaml";
      key = "blockkey";
      sopsFile = ./secrets/nextcloud.yaml;
      # owner = "nextcloud-spreed-signaling";
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
    turn-secret = {
      format = "yaml";
      key = "turn-secret";
      sopsFile = ./secrets/coturn.yaml;
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
    turn-api-key = {
      format = "yaml";
      key = "turn-api-key";
      sopsFile = ./secrets/coturn.yaml;
      # group = "nextcloud-spreed-signaling";
      mode = "0440";
    };
  };
}
