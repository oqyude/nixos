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

      imports = with inputs;  [ <nixos-wsl/modules>
        self.nixosModules.default
       ];

      i18n = {
        defaultLocale = "en_US.UTF-8";
        supportedLocales = [
          "en_US.UTF-8/UTF-8"
          "ru_RU.UTF-8/UTF-8"
        ];
      };

      #zramSwap.enable = true;
      services = {
        journald = {
          extraConfig = ''
            SystemMaxUse=512M
          '';
        };
earlyoom.enable = true;
      };
      
      networking.hostName = "${inputs.zeroq.devices.wsl.hostname}";

      wsl = {
        enable = true;
        startMenuLaunchers = true;
        #useWindowsDriver = true;
        defaultUser = "oqyude";
      };

      system.stateVersion = "24.11";
    };
in
inputs.nixpkgs.lib.nixosSystem {
  modules = [
    nixosModule
  ];
  system = "x86_64-linux";
}
