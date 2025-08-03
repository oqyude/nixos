{ inputs, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Paths
      beetsPath = "${inputs.zeroq.dirs.storage or ""}/beets/linux";
      sshPath = "${inputs.zeroq.dirs.storage or ""}/ssh/${inputs.zeroq.devices.server.hostname or ""}";
      musicPath = "${config.home.homeDirectory or ""}/External/Music";
    in
    {
      imports = [
        inputs.self.homeModules.default
      ];
      xdg = {
        configFile = {
          "beets" = {
            enable = builtins.pathExists beetsPath;
            source = config.lib.file.mkOutOfStoreSymlink beetsPath;
            target = "beets";
          };
        };
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
          ".ssh" = {
            enable = builtins.pathExists sshPath;
            source = config.lib.file.mkOutOfStoreSymlink sshPath;
            target = ".ssh";
          };
          "Music" = {
            enable = builtins.pathExists musicPath;
            source = config.lib.file.mkOutOfStoreSymlink musicPath;
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
