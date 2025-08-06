{
  config,
  lib,
  pkgs,
  ...
}:
{

  services.xserver.displayManager.lightdm.enable = true;
  #services.displayManager.defaultSession = "lomiri";
  #   services.xserver.desktopManager.budgie.enable = true;
  #services.xserver.displayManager.lightdm.greeters.lomiri.enable= true;

  #services.desktopManager.lomiri.enable = true;
  #-services.xserver.desktopManager.mate.enable = true;
  #-services.xserver.desktopManager.lxqt.enable = true;
  #   services.xserver.desktopManager.lumina.enable = true;
  #   services.xserver.desktopManager.cde.enable = true;
  #   services.xserver.desktopManager.cinnamon.enable = true;
  #   services.xserver.desktopManager.enlightenment.enable = true;
  #   services.desktopManager.cosmic.xwayland.enable = true;
  #   services.desktopManager.cosmic.enable = true;

  services.xserver = {
    enable = true;
    desktopManager = {
      #xterm.enable = false;
      xfce.enable = true;
      xfce.enableWaylandSession = true;
    };
  };

  #- services.xserver.desktopManager.pantheon.enable = true;
  #- services.pantheon.apps.enable = true;

}
