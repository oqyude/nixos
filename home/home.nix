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
      mkUser =
        username:
        {
          imports ? [ ],
          headless ? false,
        }:
        {
          inherit imports;
          home = {
            username = username;
            stateVersion = lib.mkDefault "26.05";
            homeDirectory =
              if username == "root" then lib.mkDefault "/${username}" else lib.mkDefault "/home/${username}";
            enableNixpkgsReleaseCheck = false;
          };
          # Headless hosts: no GUI user dirs
          xdg = lib.mkIf headless {
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
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users = {
          root = mkUser "root" { };
          "${xlib.device.username}" = mkUser xlib.device.username {
            imports = [
              (./. + "/${xlib.device.type}.nix")
            ];
            headless = builtins.elem xlib.device.type [
              "server"
              "vds"
              "wsl"
            ];
          };
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
