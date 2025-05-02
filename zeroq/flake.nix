{
  description = "zeroq structure flake";

  outputs =
    { self }:

    rec {

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

      nixos = "/etc/nixos";

      dirs = rec {
        # User
        user-home = "/home/${devices.admin}";
        user-storage = "${user-home}/Storage";
        therima-drive = "/mnt/therima";
        vetymae-drive = "/mnt/vetymae";
        #state-folder = ".userdata";

        # Server
        server-home = "/home/${devices.server.username}/External";
        storage = "${server-home}/Storage";
        calibre-library = "${server-home}/Books-Library";
        nextcloud-source = "${server-home}/Nextcloud";
        nextcloud-target = "/var/lib/nextcloud";
        credentials-source-server = "${server-home}/Credentials/.server";
        credentials-target = "/var/lib/credentials";
      };

      platform = {
        vfioIds = [
          "10de:25a2"
          "10de:2291"
        ];
        gpuUsbDriverId = "0000:01:00.0"; # Nvidia
      };
    };

}
