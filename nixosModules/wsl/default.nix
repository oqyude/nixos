{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../software/whisper.nix
    #../server/open-webui.nix
  ];
}
