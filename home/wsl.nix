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
      imports = [ ];
      xdg = {
        enable = true;
        autostart.enable = true;
        configFile = {
          "beets" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/beets/linux";
            target = "beets";
          };
        };
        # userDirs = {
        #   enable = false;
        #   createDirectories = false;
        #   desktop = null;
        #   documents = null;
        #   download = null;
        #   music = null;
        #   pictures = null;
        #   publicShare = null;
        #   templates = null;
        #   videos = null;
        # };
      };

      home = {
        username = "${inputs.zeroq.devices.admin}";
        file = {
          # "ssh" = {
          #   source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/ssh/${config.home.username}";
          #   target = ".ssh";
          # };
          # "External" = {
          #   source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.therima-drive}";
          #   target = "External";
          # };
        };
        # pointerCursor = {
        #   enable = true;
        #   x11.enable = true;
        #   gtk.enable = true;
        #   size = 24;
        #   name = "Qogir";
        #   package = pkgs.qogir-icon-theme;
        # };
      };
    };
  nixosModule =
    { config, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${inputs.zeroq.devices.admin} = homeModule;
        sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
        extraSpecialArgs = {
          inherit (config.networking) hostName;
        };
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
