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
              192.168.1.20 dns.zeroq.su
              192.168.1.20 immich.zeroq.su
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