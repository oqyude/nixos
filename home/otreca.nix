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
#         configFile = {
#           "ludusavi" = {
#             source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/ludusavi/cfg";
#             target = "ludusavi";
#           };
#           "nekoray" = {
#             source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.user-storage}/Nekoray/${hostname}";
#             target = "nekoray";
#           };
#         };
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = null;
          documents = "${config.home.homeDirectory}/Documents";
          download = "${config.home.homeDirectory}/Downloads";
          music = "${config.home.homeDirectory}/Music";
          pictures = "${config.home.homeDirectory}/Pictures";
          publicShare = "${config.home.homeDirectory}/Misc/public/${hostname}";
          templates = null;
          videos = "${config.home.homeDirectory}/Pictures/Videos";
          extraConfig = {
            XDG_MISC_DIR = "${config.home.homeDirectory}/Misc";
          };
        };
      };
#       dconf = {
#         settings = {
#           "org/virt-manager/virt-manager/connections" = {
#             autoconnect = ["qemu:///system"];
#             uris = ["qemu:///system"];
#           };
#         };
#       };
      home = {
        #Downloads.source = config.lib.file.mkOutOfStoreSymlink "/mnt/real/path/to/Downloads";
#         file = {
#           "luduasvi" = {
#             source = "${config.home.homeDirectory}/storage/ludusavi/cfg";
#             target = ".config/ludusavi";
#           };
#         };
        preferXdgDirectories = true;
        username = "${zeroq.server-name}";
        homeDirectory = "${zeroq.dirs.server-home}";
#         packages = with pkgs; [
#         ];
        stateVersion = "24.11";
      };

    };
  nixosModule =
    { ... }:
    {
      home-manager.users.otreca = homeModule;
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
