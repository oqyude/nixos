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
      device.type = "wsl";

      imports = with inputs; [
        nixos-wsl.nixosModules.default
        self.nixosModules.default

        self.nixosModules.software.beets
        self.nixosModules.server.open-webui
        self.homeConfigurations.wsl.nixosModule
      ];

      #zramSwap.enable = true;
      services = {
        journald = {
          extraConfig = ''
            SystemMaxUse=512M
          '';
        };
        earlyoom.enable = true;
      };

      networking = {
        firewall.enable = false;
        hostName = "${inputs.zeroq.devices.wsl.hostname}";
      };

      wsl = {
        enable = true;
        startMenuLaunchers = true;
        #useWindowsDriver = true;
        defaultUser = "${inputs.zeroq.devices.admin}";
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
