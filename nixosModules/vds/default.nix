{
  lib,
  ...
}:
{
  imports = [
    ./docker.nix
    ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
