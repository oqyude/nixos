{
  config,
  lib,
  pkgs,
  ...
}:
{
  qt = {
    enable = true;
    style = "breeze";
    platformTheme = "kde6"; # kde6
  };
  environment = {
    systemPackages = with pkgs; [
      whitesur-gtk-theme
      whitesur-icon-theme
      #whitesur-cursors
      whitesur-kde
      qogir-icon-theme
      #qogir-theme
      #qogir-kde
    ];
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      elisa
      #       kwallet
      #       kwallet-pam
      #       kwalletmanager
    ];
  };
  services = {
    displayManager = {
      sddm = {
        enable = true;
        theme = "WhiteSur-light";
        wayland = {
          enable = true;
          compositor = "kwin";
        };
      };
    };
    desktopManager.plasma6.enable = true;
  };
}
