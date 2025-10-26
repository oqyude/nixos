{
  lib,
  ...
}:
{
  imports = [
    ../software/beets
    ./calibre-web.nix
    ./immich.nix
    ./nextcloud.nix
    ./nginx.nix
    ./postgresql.nix
    ./samba.nix
    ./stirling-pdf.nix
    ./syncthing.nix
    ./systemd.nix
    ./transmission.nix
    ./uptime-kuma.nix
    # ./mealie.nix
    # ./memos.nix
    # ./miniflux.nix
    # ./node-red.nix
    # ./open-webui.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
}
