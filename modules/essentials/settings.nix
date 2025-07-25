{
  config,
  ...
}:
{
  system.nixos.label = "default";

  nix = {
    settings = {
      substituters = [
        "https://nixos-cache-proxy.cofob.dev" # https://gist.github.com/cofob/9b1fd205e6d961a45c225ae9f0af1394
        "https://nix-community.cachix.org"
      ];
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  security = {
    sudo.wheelNeedsPassword = false;
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
            if ((action.id == "org.gnome.gparted" || // for gnome
                action.id == "org.freedesktop.policykit.exec") && // for desktop, nekoray
                subject.isInGroup("wheel")){ // for sudo
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
      #"C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
  };
}
