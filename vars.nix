rec {
  user-name = "oqyude";
  server-name = "otreca";
  nixos = "/etc/nixos"; #"/home/${user-name}/zeroq"

  dirs = rec {
    # User
    user-home = "/home/${user-name}";
    user-storage = "${user-home}/Storage";
    therima-drive = "/mnt/therima";
    vetymae-drive = "/mnt/vetymae";

    # Server
    server-drive = "/mnt/server";
    server-home = "/home/${server-name}";
    sync = "${server-home}/Sync";
    storage = "${server-home}/Storage";
    calibre-library = "${server-home}/Library";
    nextcloud-source = "${server-home}/Nextcloud";
    nextcloud-target = "/var/lib/nextcloud";
    credentials-source-server = "${server-home}/Credentials/.server";
    credentials-target = "/var/lib/credentials";
  };

  platform = rec {
    cpu = "amd";
    vfioIds = [
      "10de:25a2"
      "10de:2291"
    ];
    gpuUsbDriverId = "0000:01:00.0"; # Nvidia
  };
}
