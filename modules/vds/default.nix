{
  lib,
  ...
}:
{
  imports = [
    ./containers
    ./nginx.nix
    ./xray.nix
    # ../services/uptime-kuma.nix
    # ./netbird.nix
  ];
}
