{
  config,
  lib,
  pkgs,
  ...
}:

let
  this-host = "wsl";
in
{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/etc/nixos/${this-host}/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [ <nixos-wsl/modules> ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "ru_RU.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };

  networking.hostName = "${this-host}";

  users = {
    defaultUserShell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" ];

  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    nixfmt-rfc-style
    yazi
    lf
    eza
    nodePackages.prettier
    yq-go
  ];

  programs = {
    lazygit.enable = true;
    git.enable = true;
    nh.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      zsh-autoenv.enable = true;
      loginShellInit = "clear && fastfetch";
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
      };
    };
  };

  systemd = {
    services = {
      base-start = {
        path = [ "/run/current-system/sw" ]; # Запуск в текущей системе
        script = ''
          nixfmt /etc/nixos
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
  };

  zramSwap.enable = true;
  services.earlyoom.enable = true;

  wsl = {
    enable = true;
    startMenuLaunchers = true;
    #useWindowsDriver = true;
    defaultUser = "nixos";
  };

  system.stateVersion = "24.05";
}
