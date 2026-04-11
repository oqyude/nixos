{
  lib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ./nginx.nix
    ./samba.nix
    # ./glances.nix
    # ./netbird.nix
    # ./xray.nix
  ];
}
