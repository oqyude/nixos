{
  deviceType = "wsl";
  hostname = "wsl";
  modules = [
    (
      {
        config,
        lib,
        pkgs,
        modulesPath,
        xlib,
        inputs,
        ...
      }:
      {
        imports = [
          inputs.nixos-wsl.nixosModules.default
          inputs.self.nixosModules.default
        ];

        hardware = {
          graphics.enable = true;
        };

        networking = {
          firewall = {
            enable = false;
            allowPing = true;
          };
          enableIPv6 = true;
        };

        wsl = {
          enable = true;
          startMenuLaunchers = true;
          useWindowsDriver = true;
          defaultUser = config.xlib.device.username;
        };

        system.stateVersion = "24.11";
      }
    )
  ];
}
