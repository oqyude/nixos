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
      xdg = {
        enable = true;
        autostart.enable = true;
#         systemDirs = {
#           config = [ "/etc/xdg" ];
#         };
#         configFile = {
#           "ludusavi" = {
#             source = "/home/oqyude/storage/ludusavi/cfg";
#             target = "/home/oqyude/ludusavi";
#           };
#         };
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${config.home.homeDirectory}/misc/desktops";
          documents = "${config.home.homeDirectory}/documents";
          download = "${config.home.homeDirectory}/downloads";
          music = "${config.home.homeDirectory}/music";
          pictures = "${config.home.homeDirectory}/pictures";
          publicShare = "${config.home.homeDirectory}/misc/public";
          templates = null;
          videos = "${config.home.homeDirectory}/pictures/videos";
          extraConfig = {
            XDG_MISC_DIR = "${config.home.homeDirectory}/misc";
          };
        };
      };
      dconf = {
        settings = {
          "org/virt-manager/virt-manager/connections" = {
            autoconnect = ["qemu:///system"];
            uris = ["qemu:///system"];
          };
        };
      };
      home = {
#         file = {
#           "luduasvi" = {
#             source = "${config.home.homeDirectory}/storage/ludusavi/cfg";
#             target = "${config.home.homeDirectory}/.config/ludusavi";
#           };
#         };
        preferXdgDirectories = true;
        username = "oqyude";
        homeDirectory = "/home/oqyude";
        packages = with pkgs; [
          home-manager
          btop
          mangohud
          fastfetch
          input-leap
          kdePackages.filelight
          whitesur-kde
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
          transmission_4-qt
          lutris
          gamehub
          #anydesk
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
