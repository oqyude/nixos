{
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
    #../vds/docker.nix
    #../services/tts.nix
    #../server/open-webui.nix
  ];
}
