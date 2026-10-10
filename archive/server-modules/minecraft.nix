{
  config,
  inputs,
  pkgs,
  xlib,
  ...
}:
let
  storage = xlib.helpers.mkServiceStorage {
    name = "minecraft";
    user = "minecraft";
    group = "minecraft";
    mode = "770";
  };
in
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    dataDir = "/var/lib/minecraft";
    servers = {
      vanilla = {
        enable = true;
        package = pkgs.fabricServers.fabric-26_2.override {
          jre_headless = pkgs.jdk25_headless;
        };
        jvmOpts = "-Xmx2G -Xms1G";
        enableReload = true;
        serverProperties = {
          view-distance = 6;
          simulation-distance = 4;
          online-mode = false;
          difficulty = 3;
          gamemode = 1;
          max-players = 5;
          server-port = 25565;
          motd = "ZeroQ сервак майна епта!";
          enable-rcon = true;
          "rcon.password" = "zeroq";
        };
        symlinks.mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            Lithium = pkgs.fetchurl {
              name = "lithium-fabric-0.25.3+mc26.2.jar";
              url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/f7vZ0VWU/lithium-fabric-0.25.3%2Bmc26.2.jar";
              hash = "sha256-/d6S4jjoB1+JrX9wHyo9WFSviLqaZ2VxhKRAexBKxWM=";
            };
            FerriteCore = pkgs.fetchurl {
              name = "ferritecore-9.0.0-fabric.jar";
              url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar";
              hash = "sha256-ITlmxy7ZZ6zHOSvrKKhm+6MB/1a5l2wueAHC233mvyI=";
            };
            Krypton = pkgs.fetchurl {
              name = "krypton-0.3.1.jar";
              url = "https://cdn.modrinth.com/data/fQEb0iXm/versions/5WeL0Nkz/krypton-0.3.1.jar";
              hash = "sha256-XqiQFWGXPSnlHnUUadUtkhAPNIq0YeEYb2cBLpNCDEg=";
            };
          }
        );
      };
    };
  };
  systemd = storage.systemd;
}
