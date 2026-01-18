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
        /export 192.168.1.20(rw,fsid=0,no_subtree_check,no_root_squash)
        /export/root  192.168.1.20(rw,nohide,insecure,no_subtree_check,no_root_squash)
      '';
    };
  };
  fileSystems."/export/root" = {
    device = "/";
    options = [ "bind" ];
  };
}
