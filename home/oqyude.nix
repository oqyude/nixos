{ inputs, ... }@flakeContext:
let
  homeModule = { config, lib, pkgs, ... }: {
    home = {

      username = "oqyude";

      homeDirectory = "/home/oqyude";

      packages = with pkgs; [

        btop
        mangohud
        fastfetch
        gparted
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

      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      };

      stateVersion = "24.11";
    };

  };
  nixosModule = { ... }: {
    home-manager.users.oqyude = homeModule;
  };
in
(
  (
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        homeModule
      ];
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    }
  ) // { inherit nixosModule; }
)
