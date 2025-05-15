{
  config,
  lib,
  pkgs,
  ...
}:
{
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
  };
}
