{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ../software/whisper.nix
    ./containers
    ./nix-serve.nix
    # ./tools
    #../server/open-webui.nix
    #../services/tts.nix
  ];
}
