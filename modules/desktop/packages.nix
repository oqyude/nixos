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
      curl
      ipset
      iptables
      nftables
      wget

      # Tools
      mc
      unzip
      rar
      ntfs3g
      gparted

      # Monitoring
      pciutils
      smartmontools
      usbutils
    ];
  };
  services = {
    printing = {
      enable = true;
      cups-pdf.enable = true;
    };
  };
}
