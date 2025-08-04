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
      beetsPath = "${config.xlib.dirs.wsl-storage}/beets/linux";
      #sshPath = "${config.xlib.dirs.storage}/ssh/${config.xlib.devices.server.hostname}";
      musicPath = "${config.home.homeDirectory}/External/Music";
      externalPath = "${config.xlib.dirs.wsl-home}";
    in
    {
      imports = [
        inputs.self.homeModules.default
      ];
      xdg = {
        enable = true;
        autostart.enable = true;
        configFile = {
          "beets" = {
            source = config.lib.file.mkOutOfStoreSymlink beetsPath;
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
        #username = "${config.xlib.devices.admin}";
        file = {
          "External" = {
            source = config.lib.file.mkOutOfStoreSymlink externalPath;
            target = "External";
          };
          "Music" = {
            source = config.lib.file.mkOutOfStoreSymlink musicPath;
            target = "${config.home.homeDirectory}/Music";
          };
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
        users.${config.xlib.devices.admin} = homeModule;
        # sharedModules = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];
        # extraSpecialArgs = {
        #   inherit (config.networking) hostName;
        # };
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
