{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      xlib,
      ...
    }:
    let
      mkHomeModule =
        { username }:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            (./. + "/${xlib.device.type}.nix")
          ];
          home = {
            username = username;
            stateVersion = lib.mkDefault "25.05";
            homeDirectory = if username == "root" then "/${username}" else "/home/${username}";
            enableNixpkgsReleaseCheck = false;
          };
        };

      mkModule = username: mkHomeModule { username = username; };

      homeModule = mkModule xlib.device.username;
      rootModule = mkModule "root";
      # homeModule =
      #   {
      #     config,
      #     lib,
      #     pkgs,
      #     ...
      #   }:
      #   {
      #     imports = [
      #       (./. + "/${xlib.device.type}.nix")
      #     ];
      #     home = {
      #       username = xlib.device.username;
      #       stateVersion = lib.mkDefault "25.05";
      #       homeDirectory = "/home/${config.home.username}";
      #       enableNixpkgsReleaseCheck = false;
      #     };
      #   };

      # rootModule =
      #   {
      #     config,
      #     lib,
      #     pkgs,
      #     ...
      #   }:
      #   {
      #     imports = [
      #       (./. + "/${xlib.device.type}.nix")
      #     ];
      #     home = {
      #       username = "root";
      #       stateVersion = lib.mkDefault "25.05";
      #       homeDirectory = lib.mkDefault "/${config.home.username}";
      #       enableNixpkgsReleaseCheck = false;
      #     };
      #   };

    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users = {
          "${xlib.device.username}" = homeModule;
          root = rootModule;
        };
        sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
        ];
        extraSpecialArgs = {
          inherit inputs;
          inherit xlib;
        };
      };
    };
in
{
  inherit nixosModule;
}
