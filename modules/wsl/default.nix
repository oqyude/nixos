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
    #../server/open-webui.nix
    #../services/tts.nix
  ];
  environment.systemPackages = [ 
    pkgs.rovr
  ];
}
