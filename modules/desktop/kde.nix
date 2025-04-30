{
  config,
  lib,
  pkgs,
  ...
}:
{
  qt = {
    enable = true;
    platformTheme = "kde6";
  };
  environment = {
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      elisa
      kwrited
      kwallet
      kwallet-pam
      kwalletmanager
    ];
  };
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          compositor = "kwin";
        };
      };
    };
    desktopManager.plasma6.enable = true;
  };
}
