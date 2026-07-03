{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./acme.nix
    ./bentopdf.nix
    ./calibre-web.nix
    ./chrony.nix
    ./coredns.nix
    ./gitea.nix
    ./glances.nix
    ./immich.nix
    ./miniflux.nix
    ./netdata.nix
    ./nextcloud.nix
    ./nginx.nix
    ./nix-serve.nix
    ./postgresql.nix
    ./samba.nix
    ./step-ca.nix
    ./syncthing.nix
    ./systemd.nix
    # ../containers/remnawave.nix
    # ./coturn.nix
    # ./mealie.nix
    # ./memos.nix
    # ./n8n.nix
    # ./navidrome.nix
    # ./nfs.nix
    # ./node-red.nix
    # ./open-webui.nix
    # ./rsync.nix
    # ./stirling-pdf.nix
    # ./transmission.nix
    # ./trilium.nix
    # ./uptime-kuma.nix
    # ./zerotier.nix
  ];
}
