{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {

      imports = [ <nixos-wsl/modules> ];

      i18n = {
        defaultLocale = "en_US.UTF-8";
        supportedLocales = [
          "ru_RU.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
        ];
      };

      networking.hostName = "${inputs.zeroq.devices.wsl.username}";

      users = {
        defaultUserShell = pkgs.zsh;
      };

      nixpkgs.config.allowUnfree = true;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      environment.systemPackages = with pkgs; [
        btop
        fastfetch
        yazi
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
