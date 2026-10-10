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
  # reality443Forwarding removed 2026-10-10 (T10/C5): option's purpose
  # was lost after c8d4a12 revert; nginx stream on otreca still works.
  host."3x-ui" = {
    certDomain = "pubray1.zeroq.su";
  };
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
