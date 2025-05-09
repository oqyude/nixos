{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment = {
    gnome.excludePackages = with pkgs; [
      cheese # webcam tool
      epiphany # web browser
      #evince # document viewer
      geary # email reader
      gnome-characters
      gnome-music
      gnome-user-docs
      gnome-tour
    ];
    systemPackages = with pkgs; [
      gnomeExtensions.appindicator
      gnomeExtensions.dash-to-panel
      gnomeExtensions.arcmenu
      gnomeExtensions.vitals
      gnomeExtensions.user-themes
      gnome-tweaks
      dconf-editor
      dconf2nix
    ];
  };
  services = {
    udev.packages = with pkgs; [ gnome-settings-daemon ];
    xserver = {
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      desktopManager.gnome.enable = true;
    };
  };
}
