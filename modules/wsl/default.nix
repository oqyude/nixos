{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../software/beets
    ./containers
    ./nix-serve.nix
    # ./tools
    #../server/open-webui.nix
    #../services/tts.nix
  ];
}
