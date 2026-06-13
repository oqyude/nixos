{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./bentopdf.nix
    ./calibre-web.nix
    ./gitea.nix
    ./glances.nix
    ./immich.nix
    ./miniflux.nix
    ./n8n.nix
    ./navidrome.nix
    ./netdata.nix
    ./nextcloud.nix
    ./nginx.nix
    ./nix-serve.nix
    ./open-webui.nix
    ./postgresql.nix
    ./samba.nix
    ./step-ca.nix
    ./stirling-pdf.nix
    ./syncthing.nix
    ./systemd.nix
    ./transmission.nix
    ./uptime-kuma.nix
    # ../containers/remnawave.nix
    # ./mealie.nix
    # ./memos.nix
    # ./nfs.nix
    # ./node-red.nix
    # ./rsync.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
