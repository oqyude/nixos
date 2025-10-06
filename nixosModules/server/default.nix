{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ../services/node-red.nix
    ../services/uptime-kuma.nix
    ./calibre-web.nix
    ./immich.nix
    ./miniflux.nix
    ./nextcloud.nix
    ./nginx.nix
    ./samba.nix
    ./stirling-pdf.nix
    ./syncthing.nix
    ./systemd.nix
    ./transmission.nix
    # ./mealie.nix
    # ./memos.nix
    # ./open-webui.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
