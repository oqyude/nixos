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
              192.168.1.20 agent.zeroq.su
              192.168.1.20 bentopdf.zeroq.su
              192.168.1.20 calibre.zeroq.su
              192.168.1.20 dns.zeroq.su
              192.168.1.20 flux.zeroq.su
              192.168.1.20 gitea.zeroq.su
              192.168.1.20 health.zeroq.su
              192.168.1.20 immich.zeroq.su
              192.168.1.20 kuma.zeroq.su
              192.168.1.20 n8n.zeroq.su
              192.168.1.20 nextcloud.zeroq.su
              192.168.1.20 office.zeroq.su
              109.248.161.5 x.zeroq.su
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
