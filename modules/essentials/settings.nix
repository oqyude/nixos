{
  config,
  lib,
  pkgs,
  ...
}:
{
  # new things https://git.voronind.com/voronind/nix/src/commit/c4a70068a474e9f30b8e367b69520c563e02fbd9/system/nix.nix
  system.nixos.label = "default";

  nix = {
    # package = pkgs.lixPackageSets.stable.lix; # maybe unstable
    channel.enable = false;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
    settings = {
      require-sigs = false;
      substituters = [
        "http://100.64.0.0:5000"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://mirror.yandex.ru/nixos"
        "https://cache.nixos.kz"
        # "https://cache.xd0.zip"
        "https://nixos-cache-proxy.cofob.dev"
        # "https://nixos-cache-proxy.sweetdogs.ru"
        # "https://nixos-cache-proxy.elxreno.com"
        # "https://nixos.snix.store" # https://nixos.snix.store/
      ];
      trusted-public-keys = [
        "cache.local:be5jFLkiwNyOep/McxSafB3jguBmztxx+oJ46ySyc/s="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      stalled-download-timeout = 8;
      connect-timeout = 8;
      auto-optimise-store = true;
      fallback = true;
      allow-import-from-derivation = true;
      keep-derivations = false;
      keep-outputs = false;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
    };
  };

  nixpkgs = {
    flake = {
      setFlakeRegistry = false;
      setNixPath = false;
    };
    config.allowUnfree = true;
  };

  security = {
    sudo.wheelNeedsPassword = false;
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")){ // for sudo
              return polkit.Result.YES;
          }
        });
      '';
    };
    pki.certificates = [
      ''
        -----BEGIN CERTIFICATE-----
        MIIBlDCCATmgAwIBAgIQUR+DM/LKIbokKxYPGZbCCjAKBggqhkjOPQQDAjAoMQ4w
        DAYDVQQKEwVaZXJvUTEWMBQGA1UEAxMNWmVyb1EgUm9vdCBDQTAeFw0yNjA2MTMy
        MjU2MDZaFw0zNjA2MTAyMjU2MDZaMCgxDjAMBgNVBAoTBVplcm9RMRYwFAYDVQQD
        Ew1aZXJvUSBSb290IENBMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgbhGtnlm
        qd2Uv1B1VBSeg6NlXFMj4BG/k5gVu9bVFBK4cw9HVx21aHw9HhFW94P2KaySR6bu
        K8tLDtzvs0xkyqNFMEMwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8C
        AQEwHQYDVR0OBBYEFH07/1blaqp0MVuSZIUHS9W3SjIrMAoGCCqGSM49BAMCA0kA
        MEYCIQD1coTa7hqU1PAdnamAIgq1ApadDWpWfNaXPGiLCrkxTwIhAJhj/YSzqTJR
        HvurdJ9m2glxV3rQHIUiVqKbQRcibObd
        -----END CERTIFICATE-----
      ''
    ];
  };
  systemd.network.wait-online.enable = false;

  time.timeZone = "Europe/Moscow";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
  };

  # sops.secrets = {
  #   intermediate-ca = {
  #     format = "yaml";
  #     key = "intermediate-ca";
  #     sopsFile = ./secrets/settings.yaml;
  #     # owner = "nobody";
  #     # group = "nogroup";
  #     mode = "0700";
  #   };
  #   root-ca = {
  #     format = "yaml";
  #     key = "root-ca";
  #     sopsFile = ./secrets/settings.yaml;
  #     # owner = "nobody";
  #     # group = "nogroup";
  #     mode = "0700";
  #   };
  # };
}
