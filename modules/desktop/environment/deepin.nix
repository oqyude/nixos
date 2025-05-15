{
  config,
  lib,
  pkgs,
  ...
}:
{

  #   services.xserver = {
  #     enable = true;
  #     desktopManager = {
  #       #xterm.enable = false;
  #       xfce.enable = true;
  #     };
  #   };

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.deepin.enable = true;
  services.deepin.deepin-anything.enable = true;
  services.deepin.dde-daemon.enable = true;
  services.deepin.dde-api.enable = true;
  services.deepin.app-services.enable = true;

}
