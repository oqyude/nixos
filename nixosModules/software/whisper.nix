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
  #hardware.graphics.extraPackages = with pkgs.rocmPackages; [ clr clr.icd ];
}
