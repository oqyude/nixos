# pxe-infra/http — nginx serving kernel, initramfs, and rootfs
# over HTTP, bound to the bridge interface only.
#
# Per docs/ARCHITECTURE.md §L3, HTTP is the carrier for everything
# heavy: kernel, initramfs, rootfs, and ISO. TFTP is reserved for
# the bootloader (iPXE) and lives in modules/pxe-infra/dhcp.nix
# (same dnsmasq instance).
#
# The vhost listens on the bridge IP only, not 0.0.0.0, and no
# default catch-all vhost is configured — a stray request to
# nginx on any other interface is refused at the listen layer,
# not silently answered.
{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.http.enable) {
    services.nginx = {
      enable = true;

      virtualHosts."pxe-artifacts" = {
        listen = [{
          addr = config.pxe-infra.bridge.address;
          port = config.pxe-infra.http.port;
        }];
        root = "${config.pxe-infra.artifacts.root}/http";
        # Directory listing for the artifact tree. Lets the user
        # point a browser at the bridge IP to see what versions are
        # staged. No fancy autoindex formatting.
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
  };
}
