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
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${config.home.homeDirectory}/Misc/Desktops/${inputs.zeroq.devices.admin}";
          documents = "${config.home.homeDirectory}/Documents";
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
      dconf = {
        settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = [ "qemu:///system" ];
            uris = [ "qemu:///system" ];
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = with pkgs.gnomeExtensions; [
              dash-to-panel.extensionUuid
              arcmenu.extensionUuid
              vitals.extensionUuid
              appindicator.extensionUuid
            ];
            disabled-extensions = [ ];
          };
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-light";
            enable-hot-corners = false;
          };
        };
      };
      services = {
        kdeconnect.enable = true;
        easyeffects.enable = true;
      };

      programs = {
        fastfetch.enable = true;
        btop.enable = true;
        mangohud.enable = true;
        keepassxc.enable = true;
        zed-editor = {
          enable = true;
          extensions = [
            "nix"
          ];
          userSettings = {
            "telemetry" = {
              "diagnostics" = false;
              "metrics" = false;
            };
            "ui_font_size" = 20;
            "buffer_font_size" = 26;
            "theme" = {
              "mode" = "system";
              "light" = "Ayu Light";
              "dark" = "Ayu Dark";
            };
          };
        };
      };

      home = {
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
          "Documents" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Public Documents";
            target = "Documents";
          };
          "Misc" = {
            source = config.lib.file.mkOutOfStoreSymlink "${inputs.zeroq.dirs.vetymae-drive}/Users/User/Misc";
            target = "Misc";
          };
        };
        #preferXdgDirectories = true;
        username = "${inputs.zeroq.devices.admin}";
        homeDirectory = "/home/${inputs.zeroq.devices.admin}";
        stateVersion = "24.11";
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
