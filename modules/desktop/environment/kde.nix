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
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.plasma-browser-integration
    kdePackages.elisa
    kdePackages.ksshaskpass
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager
    libsForQt5.kwallet
    libsForQt5.kwallet-pam
    libsForQt5.kwalletmanager
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
  programs.partition-manager.enable = true;
}
