{
  config,
  pkgs,
  xlib,
  ...
}:
# CoreDNS — the authoritative server for the `zeroq.su` (public) and
# `home.arpa` (LAN-only) zones.
#
# Every address here comes from the fleet registry (lib/xlib/net.nix): the
# zone and the nginx vhosts have to agree, and a DHCP lease that moved must
# not leave half of the zone pointing at the old machine.
{
  services.coredns = {
    enable = true;
    config = ''
      zeroq.su:53 {
          hosts {
              ${xlib.net.hosts.otreca.public} x.zeroq.su
              ${xlib.net.hosts.sapphira.lan} authelia.zeroq.su
              ${xlib.net.hosts.sapphira.lan} calibre.zeroq.su
              ${xlib.net.hosts.sapphira.lan} dns.zeroq.su
              ${xlib.net.hosts.sapphira.lan} flux.zeroq.su
              ${xlib.net.hosts.sapphira.lan} git.zeroq.su
              ${xlib.net.hosts.sapphira.lan} glances.zeroq.su
              ${xlib.net.hosts.sapphira.lan} herdr.zeroq.su
              ${xlib.net.hosts.sapphira.lan} homebox.zeroq.su
              ${xlib.net.hosts.sapphira.lan} immich.zeroq.su
              ${xlib.net.hosts.sapphira.lan} kuma.zeroq.su
              ${xlib.net.hosts.sapphira.lan} navidrome.zeroq.su
              ${xlib.net.hosts.sapphira.lan} nextcloud.zeroq.su
              ${xlib.net.hosts.sapphira.lan} open.zeroq.su
              ${xlib.net.hosts.sapphira.lan} office.zeroq.su
              ${xlib.net.hosts.sapphira.lan} pdf.zeroq.su
              ${xlib.net.hosts.sapphira.lan} syncthing.zeroq.su
              ${xlib.net.hosts.sapphira.lan} talk.zeroq.su
              ${xlib.net.hosts.sapphira.lan} turn.zeroq.su
              ${xlib.net.hosts.sapphira.lan} vtimeline.zeroq.su
              fallthrough
          }
          cache 300
          log
      }
      home.arpa:53 {
          hosts {
              ${xlib.net.hosts.vetymae.lan} vetymae.home.arpa
              ${xlib.net.hosts.sapphira.lan} ca.home.arpa
              ${xlib.net.hosts.sapphira.lan} calibre.home.arpa
              ${xlib.net.hosts.sapphira.lan} dns.home.arpa
              ${xlib.net.hosts.sapphira.lan} flux.home.arpa
              ${xlib.net.hosts.sapphira.lan} git.home.arpa
              ${xlib.net.hosts.sapphira.lan} glances.home.arpa
              ${xlib.net.hosts.sapphira.lan} home.arpa
              ${xlib.net.hosts.sapphira.lan} homebox.home.arpa
              ${xlib.net.hosts.sapphira.lan} immich.home.arpa
              ${xlib.net.hosts.sapphira.lan} kuma.home.arpa
              ${xlib.net.hosts.sapphira.lan} navidrome.home.arpa
              ${xlib.net.hosts.sapphira.lan} nextcloud.home.arpa
              ${xlib.net.hosts.sapphira.lan} office.home.arpa
              ${xlib.net.hosts.sapphira.lan} pdf.home.arpa
              ${xlib.net.hosts.sapphira.lan} sapphira.home.arpa
              ${xlib.net.hosts.sapphira.lan} syncthing.home.arpa
              fallthrough
          }
          cache 300
          log
      }
      .:53 {
          forward . ${xlib.net.hosts.router.lan} ${xlib.net.dns.cloudflare}
          cache 300
      }
    '';
  };
}
