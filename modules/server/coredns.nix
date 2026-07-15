{
  config,
  pkgs,
  ...
}:
{
  services.coredns = {
    enable = true;
    config = ''
      zeroq.su:53 {
          hosts {
              109.248.161.5 x.zeroq.su
              192.168.1.20 calibre.zeroq.su
              192.168.1.20 dns.zeroq.su
              192.168.1.20 flux.zeroq.su
              192.168.1.20 git.zeroq.su
              192.168.1.20 glances.zeroq.su
              192.168.1.20 homebox.home.arpa
              192.168.1.20 immich.zeroq.su
              192.168.1.20 kuma.zeroq.su
              192.168.1.20 nextcloud.zeroq.su
              192.168.1.20 office.zeroq.su
              192.168.1.20 pdf.zeroq.su
              192.168.1.20 syncthing.zeroq.su
              192.168.1.20 talk.zeroq.su
              192.168.1.20 turn.zeroq.su
              fallthrough
          }
          cache 300
          log
      }
      home.arpa:53 {
          hosts {
              192.168.1.100 vetymae.home.arpa
              192.168.1.20 ca.home.arpa
              192.168.1.20 calibre.home.arpa
              192.168.1.20 dns.home.arpa
              192.168.1.20 flux.home.arpa
              192.168.1.20 git.home.arpa
              192.168.1.20 glances.home.arpa
              192.168.1.20 home.arpa
              192.168.1.20 homebox.home.arpa
              192.168.1.20 immich.home.arpa
              192.168.1.20 kuma.home.arpa
              192.168.1.20 nextcloud.home.arpa
              192.168.1.20 office.home.arpa
              192.168.1.20 pdf.home.arpa
              192.168.1.20 sapphira.home.arpa
              192.168.1.20 syncthing.home.arpa
              fallthrough
          }
          cache 300
          log
      }
      .:53 {
          forward . 1.1.1.1 9.9.9.9
          cache 300
      }
    '';
  };
}
