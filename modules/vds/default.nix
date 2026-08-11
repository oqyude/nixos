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
    # ./xray.nix
  ];
  systemd.tmpfiles.rules = [
    (xlib.helpers.mkTmpfile "d" "/mnt" "0755" "root" "root")
    (xlib.helpers.mkTmpfile "d" xlib.dirs.services-mnt-folder "0755" "root" "root")
  ];
}
