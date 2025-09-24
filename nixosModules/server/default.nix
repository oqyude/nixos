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
    #./cloudflared.nix
  ];
}
