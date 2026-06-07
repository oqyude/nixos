{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/aichat.nix
    ../software/beets
    ../software/whisper.nix
    ./containers
    ./tools
    #../server/open-webui.nix
    #../services/tts.nix
  ];
}
