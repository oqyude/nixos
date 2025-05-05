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
        server-home = "/home/${devices.server.username}/External";
        storage = "${server-home}/Storage";
        calibre-library = "${server-home}/Books-Library";
        #         credentials-source-server = "${server-home}/Credentials/.server";
        #         credentials-target = "/var/lib/credentials";
      };

      #       platform = {
      #         vfioIds = [
      #           "10de:25a2"
      #           "10de:2291"
      #         ];
      #         gpuUsbDriverId = "0000:01:00.0"; # Nvidia
      #       };
    };

}
