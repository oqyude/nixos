{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services.tts.servers = {
    russian = {
      enable = true;
      port = 5301;
    };
    english = {
      #enable = false;
      port = 5300;
    };
  };
}
