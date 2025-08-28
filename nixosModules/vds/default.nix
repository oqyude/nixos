{
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    ./docker.nix
    ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
