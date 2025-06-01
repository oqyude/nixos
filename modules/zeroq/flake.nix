{
  description = "zeroq structure flake";

  outputs =
    { self }:

    rec {

      nixos = "/etc/nixos";

      devices = rec {
        admin = "oqyude";
        laptop = {
          hostname = "atoridu";
        };
        mini-laptop = {
          hostname = "lamet";
        };
        server = {
          username = "otreca";
          hostname = "sapphira";
        };
        wsl.hostname = "wsl";
      };

      dirs = rec {
        # User
        user-home = "/home/${devices.admin}";
        user-storage = "${user-home}/Storage";
        therima-drive = "/mnt/therima";
        vetymae-drive = "/mnt/vetymae";

        # Server
        server-home = "/home/${devices.admin}/External";
        storage = "${server-home}/Storage";
        calibre-library = "${server-home}/Books-Library";
        music-library = "${dirs.user-home}/Music";
        immich-folder = "${server-home}/Services/immich";
        postgresql-folder = "${server-home}/Services/postgresql";
      };
    };

}
