{
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    ./3x-ui.nix
    ./netbird.nix
    ./nginx.nix
    ./xray.nix
  ];
}
