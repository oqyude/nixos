{
  config,
  lib,
  ...
}:
{
  imports = [
    ./stirling-pdf.nix
    #./cloudflared.nix
    ./immich.nix
  ];
}
