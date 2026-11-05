{
  config,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      #qogir-kde
      #qogir-theme
      qogir-icon-theme
      whitesur-cursors # WhiteSur look-and-feel sets this cursor; without it
                       # kwin logs `Failed to load cursor theme "WhiteSur-cursors"`
      whitesur-gtk-theme
      whitesur-icon-theme
      whitesur-kde
    ];
  };
}
