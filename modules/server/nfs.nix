{
  config,
  lib,
  xlib,
  ...
}:
{
  systemd.tmpfiles.rules = [
    "z /export 0755 nobody nogroup -"
  ];
  services.nfs = {
    server = {
      enable = true;
      exports = ''
        /export         192.168.1.20(rw,fsid=0,no_subtree_check) 192.168.1.102(rw,fsid=0,no_subtree_check)
        /export/root  192.168.1.20(rw,nohide,insecure,no_subtree_check) 192.168.1.102(rw,nohide,insecure,no_subtree_check)
      '';
    };
  };
  fileSystems."/export/root" = {
    device = "/";
    options = [ "bind" ];
  };
}
