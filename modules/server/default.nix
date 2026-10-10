{
  lib,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ../containers/open-webui.nix
    ../containers/tape-rotation.nix
    ../pkgs/beets.nix
    ./acme.nix
    ./authelia.nix
    ./bentopdf.nix
    ./builder.nix
    ./calibre-web.nix
    ./chrony.nix
    ./coredns.nix
    ./gitea.nix
    ./glances.nix
    ./homebox.nix
    ./immich.nix
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
    ./ttyd.nix
    ./vtimeline.nix
    ./uptime-kuma.nix
    # 14 modules archived to ../archive/{server-modules,containers}/ on
    # 2026-10-09 (task E3 / T16). Reason: each was disabled individually
    # over time; restoring requires re-enabling the import AND ensuring
    # data mount + secrets are in place. Re-enable in a separate task.
  ];
  # Server's 3x-ui is the controller panel at x.zeroq.su (nginx HTTP
  # terminates TLS upstream, no SNI-routing on 443 needed here because
  # there are other vhosts on the same port). Cert is still mounted in
  # case 3x-ui is later reconfigured to terminate TLS itself (e.g. for
  # direct node-API access); nginx doesn't have to use it.
  host."3x-ui".certDomain = "x.zeroq.su";
  # Authelia SSO — currently protects vtimeline.zeroq.su (replaces the
  # previous nginx auth_basic htpasswd). Cookie domain is .zeroq.su so a
  # single Authelia session covers every protected vhost under the zone.
  host.authelia = {
    enable = true;
    cookieDomain = "zeroq.su";
  };
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
