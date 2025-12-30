{ inputs, ... }@flakeContext:
let
  nixosModule =
    {
      config,
      lib,
      pkgs,
      xlib,
      ...
    }:
    let
      mkHomeModule = username: {
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
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users = {
          "${xlib.device.username}" = mkHomeModule xlib.device.username;
          root = mkHomeModule "root";
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
