{
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    ./open-webui.nix
    ../software/beets
    ./calibre-web.nix
    # ./memos.nix
    # ./trilium.nix
    ./immich.nix
    # ./mealie.nix
    ./miniflux.nix
    ./nextcloud.nix
    ./nginx.nix
    ./samba.nix
    ./stirling-pdf.nix
    ./syncthing.nix
    ./systemd.nix
    ./transmission.nix
    # ./zerotier.nix
  ];
}
