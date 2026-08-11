{
  lib,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ../pkgs/beets.nix
    ./acme.nix
    ./bentopdf.nix
    ./calibre-web.nix
    ./chrony.nix
    ./coredns.nix
    ./gitea.nix
    ./glances.nix
    ./homebox.nix
    ./immich.nix
    # ./minecraft.nix
    ./miniflux.nix
    ./navidrome.nix
    ./nextcloud.nix
    ./nginx.nix
    ./nix-serve.nix
    ./onlyoffice.nix
    ./postgresql.nix
    ./power.nix
    ./samba.nix
    ./syncthing.nix
    ./systemd.nix
    ./uptime-kuma.nix
    # ../containers/remnawave.nix
    # ./coturn.nix
    # ./mealie.nix
    # ./memos.nix
    # ./n8n.nix
    # ./netdata.nix
    # ./nfs.nix
    # ./open-webui.nix
    # ./rsync.nix
    # ./step-ca.nix
    # ./stirling-pdf.nix
    # ./transmission.nix
    # ./trilium.nix
    # ./zerotier.nix
  ];
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
