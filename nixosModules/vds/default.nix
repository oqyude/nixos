{
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
