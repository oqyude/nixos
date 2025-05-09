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
      imports = [ ] ++ (builtins.attrValues inputs.self.homeModules);
      xdg = {
        enable = true;
        autostart.enable = true;
        configFile = {
          "ludusavi" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/ludusavi/cfg";
            target = "ludusavi";
          };
          "nekoray" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/Nekoray/${inputs.zeroq.devices.admin}";
            target = "nekoray";
          };
          "solaar" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/solaar";
            target = "solaar";
          };
          "easyeffects" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/easyeffects";
            target = "easyeffects";
          };
          "keepassxc" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/KeePassXC";
            target = "keepassxc";
          };
        };
        #systemDirs.config = ["/etc/xdg"];
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${config.xdg.dataHome}/desktop";
          documents = null;
          download = "${config.home.homeDirectory}/Downloads";
          music = "${config.home.homeDirectory}/Music";
          pictures = "${config.home.homeDirectory}/Pictures";
          publicShare = "${config.home.homeDirectory}/Misc/Public";
          templates = null;
          videos = "${config.home.homeDirectory}/Pictures/Videos";
          extraConfig = {
            XDG_MISC_DIR = "${config.home.homeDirectory}/Misc";
          };
        };
      };

      home = {
        username = "${inputs.zeroq.devices.admin}";
        homeDirectory = "/home/${inputs.zeroq.devices.admin}";
        stateVersion = "25.05";
        file = {
          "ssh" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.user-storage}/SSH/${inputs.zeroq.devices.admin}";
            target = ".ssh";
          };
          "External" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.therima-drive}";
            target = "External";
          };
          "Music" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Music";
            target = "Music";
          };
          "Pictures" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Pictures";
            target = "Pictures";
          };
          "Deploy" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Deploy";
            target = "Deploy";
          };
          "Misc" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Misc";
            target = "Misc";
          };
        };
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
