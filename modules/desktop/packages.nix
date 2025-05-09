{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    adb.enable = true;
    gamemode.enable = true;
    tuxclocker = {
      enable = false;
      enableAMD = true;
      useUnfree = true;
    };
    steam.enable = true;
    gamescope.enable = true;
  };
  environment = {
    systemPackages = with pkgs; [
      # Net
      #ipset
      #iptables
      #nftables

      # Tools
      #ntfs3g
      #gparted

      # Monitoring
      pciutils
      smartmontools
      usbutils
      #xiccd
      #argyllcms
      #colord
    ];
  };
  services = {
    printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };
}
