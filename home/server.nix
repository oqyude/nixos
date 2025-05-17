{ inputs, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.self.homeModules.default
        inputs.self.homeModules.links
      ];
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
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.storage}/SSH/${inputs.zeroq.devices.server.hostname}";
            target = ".ssh";
          };
          "Music" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/External/Music";
            target = "${config.home.homeDirectory}/Music";
          };
        };
        username = "${inputs.zeroq.devices.admin}";
      };

    };
  nixosModule =
    { ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${inputs.zeroq.devices.admin} = homeModule;
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
