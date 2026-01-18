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
          homeDirectory = if username == "root" then lib.mkDefault "/${username}" else lib.mkDefault "/home/${username}";
          enableNixpkgsReleaseCheck = false;
        };
      };
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users = {
          root = mkHomeModule "root";
          "${xlib.device.username}" = mkHomeModule xlib.device.username;
          # "${xlib.users.new}" = mkHomeModule xlib.users.new;
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
