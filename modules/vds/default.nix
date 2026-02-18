{
  lib,
  ...
}:
{
  imports = [
    ./containers.nix
    # ../services/uptime-kuma.nix
    # ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
