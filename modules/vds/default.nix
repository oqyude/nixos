{
  lib,
  ...
}:
{
  imports = [
    ../containers/3x-ui.nix
    ./nginx.nix
    # ./xray.nix
    # ./netbird.nix
  ];
}
