{
  lib,
  xlib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ./nginx.nix
    ./samba.nix
    ./systemd.nix
    # ./glances.nix
    # ./netbird.nix
  ];
  # VDS hosts the public-facing Xray REALITY inbound on container:443,
  # fronted by nginx stream on host:443 → host:15380 → container:443.
  # reality443Forwarding MUST stay true here: modules/vds/nginx.nix
  # routes pubrayx1.zeroq.su/default → 127.0.0.1:15380, which only
  # exists when this mapping is published. (Restored 2026-10-10 after
  # T10/C5 wrongly removed it and broke Xray REALITY.)
  host."3x-ui" = {
    certDomain = "pubray1.zeroq.su";
    reality443Forwarding = true;
  };
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
