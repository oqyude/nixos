{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  programs = {
    plasma = {
      enable = true;
      workspace = {
        #clickItemTo = "open"; # If you liked the click-to-open default from plasma 5
        lookAndFeel = "com.github.vinceliuice.WhiteSur-alt";
        cursor = {
          theme = "Qogir";
          size = 24;
        };
        iconTheme = "WhiteSur-light";
        #wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
      };
    };
  };
}
