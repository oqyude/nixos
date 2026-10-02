# Well-known paths. Everything derives from `username`, which is why the
# whole set can be computed outside the module system.
username:
let
  user-home = "/home/${username}";
  wsl-home = "/mnt/c/Users/${username}";
  server-home = "${user-home}/External";
  services-mnt-folder = "/mnt/services";
in
{
  inherit
    user-home
    wsl-home
    server-home
    services-mnt-folder
    ;

  user-storage = "${user-home}/Storage";
  wsl-storage = "${wsl-home}/Storage";
  server-credentials = "${server-home}/Credentials/server";
  storage = "${server-home}/Storage";
  calibre-library = "${server-home}/Books-Library";
  services-folder = "${server-home}/Services";
  services-nodes-folder = "${services-mnt-folder}/nodes";
  postgresql-folder = "${services-mnt-folder}/postgresql";
  music-library = "${user-home}/Music";

  archive-drive = "/mnt/archive";
  lamet-drive = "/mnt/lamet";
  mobile-drive = "/mnt/mobile";
  therima-drive = "/mnt/therima";
  vetymae-drive = "/mnt/vetymae";
  soptur-drive = "/mnt/soptur";
}
