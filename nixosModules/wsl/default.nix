{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../software/whisper.nix
    ../services/whisper.nix
    #../server/open-webui.nix
  ];
}
