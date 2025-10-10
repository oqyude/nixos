{
  lib,
  ...
}:
{
  imports = [
    ./docker.nix
    # ../services/uptime-kuma.nix
    # ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
