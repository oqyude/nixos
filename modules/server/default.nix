{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./node-red.nix
    ./uptime-kuma.nix
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
