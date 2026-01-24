{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./calibre-web.nix
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
    # ./rsync.nix
    # ./nfs.nix
    # ./mealie.nix
    # ./memos.nix
    # ./node-red.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
