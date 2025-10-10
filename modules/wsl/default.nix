{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../software/whisper.nix
    ../software/aichat.nix
    #../vds/docker.nix
    #../services/tts.nix
    #../server/open-webui.nix
  ];
}
