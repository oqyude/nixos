{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../software/whisper.nix
    ../services/tts.nix
    #../server/open-webui.nix
  ];
}
