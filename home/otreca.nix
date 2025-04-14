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
#       dconf = {
#         settings = {
#           "org/virt-manager/virt-manager/connections" = {
#             autoconnect = ["qemu:///system"];
#             uris = ["qemu:///system"];
#           };
#         };
#       };
      home = {
        file = {
          "ssh" = {
            source = config.lib.file.mkOutOfStoreSymlink "${zeroq.dirs.storage}/SSH/${hostname}";
            target = ".ssh";
          };
        };
        preferXdgDirectories = true;
        username = "${zeroq.server-name}";
        homeDirectory = "/home/${zeroq.server-name}";
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
