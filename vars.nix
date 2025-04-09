rec {
  admin = "oqyude";

  dirs = rec {
    # User
    user-home = "/home/${admin}";
    user-storage = "${user-home}/Storage";
    sound-drive = "/mnt/sound";
    windows-drive = "/mnt/windows";

    # Server
    server-home = "/mnt/server";
    sync = "${server-home}/Sync";
    storage = "${server-home}/Storage";
    calibre-library = "${server-home}/Library";
    nextcloud-source = "${server-home}/Nextcloud";
    nextcloud-target = "/var/lib/nextcloud";
    credentials-source-server = "${server-home}/Credentials/.server";
    credentials-target = "/var/lib/credentials";
  };

  channels = rec {
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
    musnix = builtins.fetchTarball "https://github.com/musnix/musnix/archive/master.tar.gz";
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
