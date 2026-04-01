{
  lib,
  ...
}:
{
  imports = [
    ../containers/remnawave.nix
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
    ./netdata.nix
    ./n8n.nix
    # ./mealie.nix
    # ./memos.nix
    # ./nfs.nix
    # ./node-red.nix
    # ./rsync.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
