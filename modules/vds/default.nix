{
  lib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ./nginx.nix
    ./samba.nix
    # ./xray.nix
    # ./netbird.nix
  ];
}
