{ inputs, ... }@flakeContext:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      hostname,
      ...
    }:
    let
      zeroq = import ../vars.nix;
    in
    {
      xdg = {
        enable = true;
        autostart.enable = true;
        configFile = {
          "ludusavi" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/ludusavi/cfg";
            target = "ludusavi";
          };
          "nekoray" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/Nekoray/${hostname}";
            target = "nekoray";
          };
          "solaar" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/solaar";
            target = "solaar";
          };
        };
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${config.home.homeDirectory}/Misc/desktops/${hostname}";
          documents = "${config.home.homeDirectory}/Documents";
          download = "${config.home.homeDirectory}/Downloads";
          music = "${config.home.homeDirectory}/Music";
          pictures = "${config.home.homeDirectory}/Pictures";
          publicShare = "${config.home.homeDirectory}/Misc/public";
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
          #"org/gnome/shell/extensions/user-theme" = {
          #  name = "palenight";
          #};
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-light";
            enable-hot-corners = false;
          };
        };
      };
      #       services = {
      #         kdeconnect = {
      #           enable = true;
      #           indicator = true;
      #         };
      #       };

      qt = {
        enable = true;
        platformTheme.name = "adwaita";
        style = {
          name = "adwaita";
        };

      };
      home = {
        file = {
          "ssh" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/SSH/${hostname}";
            target = ".ssh";
          };
          "External" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.therima-drive}";
            target = "External";
          };
        };
        #preferXdgDirectories = true;
        username = "${zeroq.user-name}";
        homeDirectory = "/home/${zeroq.user-name}";
        packages = with pkgs; [
          flameshot
          gnomeExtensions.appindicator
          gnomeExtensions.dash-to-panel
          gnomeExtensions.arcmenu
          #gnomeExtensions.tray-icons-reloaded
          gnomeExtensions.vitals
          #gnomeExtensions.user-themes
          gnome-tweaks
          dconf-editor
          dconf2nix
          #whitesur-gtk-theme
          #whitesur-icon-theme
          #whitesur-kde
          btop
          mangohud
          fastfetch
          kdePackages.filelight
          localsend
          ludusavi
          easyeffects
          brave
          # Workflow
          pdfarranger
          libreoffice-qt6
          vlc # Видео
          gramps # Genealogy
          stretchly
          nekoray
          discord
          _64gram
          keepassxc
          obsidian
          reaper
          lutris
          transmission_4-qt
          #gamehub

          audacious
          quodlibet
          gnome-music
          lollypop

          #edid-decode
          #displaycal
          #argyllcms
        ];
        stateVersion = "24.11";
      };
    };
  nixosModule =
    { ... }:
    {
      home-manager.users.oqyude = homeModule;
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
