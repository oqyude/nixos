{
  config,
  lib,
  pkgs,
  ...
}:
{
  # qt = {
  #   enable = true;
  #   style = "breeze";
  #   platformTheme = "kde6"; # kde6
  # };
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.plasma-browser-integration
    kdePackages.elisa
    kdePackages.ksshaskpass
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kwalletmanager
  ];
  services = {
    displayManager = {
      sddm = {
        enable = true;
        theme = "WhiteSur-light";
        # Required by the WhiteSur SDDM themes (see the note in
        # pkgs/by-name/wh/whitesur-kde/package.nix): the greeter needs the
        # org.kde.breeze.components QML module from plasma-desktop and qtsvg
        # for the theme's SVG assets.
        extraPackages = with pkgs; [
          kdePackages.plasma-desktop
          kdePackages.qtsvg
        ];
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
