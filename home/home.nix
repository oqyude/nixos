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
          stateVersion = lib.mkDefault "26.05";
          homeDirectory =
            if username == "root" then lib.mkDefault "/${username}" else lib.mkDefault "/home/${username}";
          enableNixpkgsReleaseCheck = false;
        };
        # Headless hosts: no GUI user dirs
        xdg =
          lib.mkIf
            (builtins.elem xlib.device.type [
              "server"
              "vds"
              "wsl"
            ])
            {
              enable = true;
              autostart.enable = true;
              userDirs = {
                enable = true;
                createDirectories = false;
                desktop = null;
                documents = null;
                download = null;
                music = null;
                pictures = null;
                publicShare = null;
                templates = null;
                videos = null;
              };
            };
      };
      mkRootModule = username: {
        home = {
          username = username;
          stateVersion = lib.mkDefault "26.05";
          homeDirectory =
            if username == "root" then lib.mkDefault "/${username}" else lib.mkDefault "/home/${username}";
          enableNixpkgsReleaseCheck = false;
        };
      };
      mkOthersModule = username: {
        imports = [
          (./. + "/others/${xlib.device.type}.nix")
        ];
        home = {
          username = username;
          stateVersion = lib.mkDefault "26.05";
          homeDirectory =
            if username == "root" then lib.mkDefault "/${username}" else lib.mkDefault "/home/${username}";
          enableNixpkgsReleaseCheck = false;
        };
      };
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users = {
          root = mkRootModule "root";
          "${xlib.device.username}" = mkHomeModule xlib.device.username;
        }
        //
          lib.optionalAttrs
            (builtins.elem xlib.device.type [
              "test"
              #"secondary"
              #"primary"
            ])
            {
              snity = mkOthersModule "snity";
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
