{
  config,
  lib,
  ...
}:
{
  system.nixos.label = "default";

  nix = {
    channel = {
      enable = true;
    };
    # nixPath = [ "nixpkgs=flake:nixpkgs" ];
    settings = {
      require-sigs = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://mirror.yandex.ru/nixos"
        "https://cache.nixos.kz"
        "https://cache.xd0.zip"
        "https://nixos-cache-proxy.cofob.dev"
        # "https://nixos-cache-proxy.sweetdogs.ru"
        # "https://nixos-cache-proxy.elxreno.com"
        # "https://nixos.snix.store" # https://nixos.snix.store/
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      stalled-download-timeout = 4;
      connect-timeout = 4;
      auto-optimise-store = true;
      # fallback = true;
      # allow-import-from-derivation = false;
      # keep-derivations = true;
      # keep-outputs = true;
      experimental-features = [
        "flakes"
        "nix-command"
      ];
    };
  };

  nixpkgs = {
    # flake = {
    #   setFlakeRegistry = false;
    #   setNixPath = false;
    # };
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
}
