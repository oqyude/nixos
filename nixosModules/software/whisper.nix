{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  environment.systemPackages = [
    pkgs.openai-whisper
  ];
}
