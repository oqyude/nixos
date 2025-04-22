{ inputs, zeroq, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      xdg = {
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
      home = {
        file = {
          "ssh" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.storage}/SSH/${zeroq.devices.server.hostname}";
            target = ".ssh";
          };
        };
        username = "${zeroq.devices.server.username}";
        homeDirectory = "/home/${zeroq.devices.server.username}";
        stateVersion = "24.11";
      };

    };
  nixosModule =
    { ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${zeroq.devices.server.username} = homeModule;
      };
    };
in
(
  (inputs.home-manager.lib.homeManagerConfiguration {
    modules = [
      homeModule
    ];
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  })
  // {
    inherit nixosModule;
  }
)
