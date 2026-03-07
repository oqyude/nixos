{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../server/containers/openhands.nix
    # ../software/ai-agent.nix
    ../software/aichat.nix
    ../software/beets
    ../software/whisper.nix
    ./containers
    #../vds/docker.nix
    #../services/tts.nix
    #../server/open-webui.nix
  ];
}
