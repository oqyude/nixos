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
      #whitesur-cursors
      qogir-icon-theme
      whitesur-gtk-theme
      whitesur-icon-theme
      whitesur-kde
    ];
  };
}
