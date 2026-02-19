{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./calibre-web.nix
    ./containers
    ./immich.nix
    ./miniflux.nix
    ./nextcloud.nix
    ./nginx.nix
    ./open-webui.nix
    ./postgresql.nix
    ./samba.nix
    ./stirling-pdf.nix
    ./syncthing.nix
    ./systemd.nix
    ./transmission.nix
    ./uptime-kuma.nix
    # ./mealie.nix
    # ./memos.nix
    # ./nfs.nix
    # ./node-red.nix
    # ./rsync.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
