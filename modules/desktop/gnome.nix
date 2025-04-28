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
      #gnome-photos
      gnome-tour
    ];
  };
}
