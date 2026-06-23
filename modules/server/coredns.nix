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
              192.168.1.20 calibre.home.arpa
              192.168.1.20 dns.home.arpa
              192.168.1.20 flux.home.arpa
              192.168.1.20 git.home.arpa
              192.168.1.20 immich.home.arpa
              192.168.1.20 kuma.home.arpa
              192.168.1.20 nextcloud.home.arpa
              192.168.1.20 office.home.arpa
              192.168.1.20 pdf.home.arpa
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
