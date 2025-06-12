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
        #inputs.self.homeModules.links
      ] /*++ (builtins.attrValues inputs.self.homeModules)*/;
      xdg = {
        configFile = {
          "beets" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.storage}/beets/linux";
            target = "beets";
          };
        };
        enable = true;
        autostart.enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = null;
          documents = null;
          download = "${config.home.homeDirectory}/Downloads";
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
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.storage}/ssh/${inputs.zeroq.devices.server.hostname}";
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
        sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
        #         extraSpecialArgs = {
        #           inherit (config.networking) hostName;
        #         };
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
