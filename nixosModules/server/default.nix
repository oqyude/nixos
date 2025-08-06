{
  config,
  lib,
  ...
}:
{
  imports = [
    #./cloudflared.nix
    ../software/beets
    ./immich.nix
    ./nextcloud.nix
    ./nginx.nix
    ./stirling-pdf.nix
  ];
}
