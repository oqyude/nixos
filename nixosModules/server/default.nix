{
  config,
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    #./nextcloud.nix
    ../software/beets
    ./immich.nix
    ./nginx.nix
    ./stirling-pdf.nix
  ];
}
