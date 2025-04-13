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
        systemDirs = {
          config = [ "/etc/xdg" ];
        };
        userDirs = {
          createDirectories = true;
          publicShare = "${config.home.homeDirectory}/public";
          videos = "${config.home.homeDirectory}/pictures";
          desktop = "${config.home.homeDirectory}/misc/desktops";
          templates = null;
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
#             recursive = true;
#             source = "${config.home.homeDirectory}/storage/ludusavi/cfg";
#             target = "${config.home.homeDirectory}/.config/ludusavi";
#           };
#         };
        username = "oqyude";
        homeDirectory = "/home/oqyude";
        packages = with pkgs; [
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
