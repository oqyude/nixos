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
        package = pkgs.minecraftServers.vanilla-26_2;
        jvmOpts = "-Xmx2G -Xms1G";
        enableReload = true;
        serverProperties = {
          online-mode = false;
          difficulty = 3;
          gamemode = 1;
          max-players = 5;
          server-port = 25565;
          motd = "ZeroQ сервак майна епта!";
          enable-rcon = true;
          "rcon.password" = "zeroq";
        };
      };
    };
  };
  systemd = storage.systemd;
}
