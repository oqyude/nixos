{
  lib,
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
    "d /mnt 0755 root root -"
    "d /mnt/services 0755 root root -"
    "d /mnt/services/containers 0755 root root -"
  ];
}
