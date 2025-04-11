{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      inputs,
      modulesPath,
      ...
    }:
    let
      current.host = "wsl";
      zeroq = import ../vars.nix;
    in
    {

      imports = [ <nixos-wsl/modules> ];

      i18n = {
        defaultLocale = "en_US.UTF-8";
        supportedLocales = [
          "ru_RU.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
        ];
      };

      networking.hostName = "${current.host}";

      users = {
        defaultUserShell = pkgs.zsh;
      };

      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      environment.systemPackages = with pkgs; [
        btop
        eza
        fastfetch
        lf
        nixfmt-rfc-style
        nodePackages.prettier
        yazi
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
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule
  ];
  system = "x86_64-linux";
}
