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
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    elisa
    #       kwallet
    #       kwallet-pam
    #       kwalletmanager
  ];
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
