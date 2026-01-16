{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # environment.systemPackages = with pkgs; [
  #   # inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  # ];
  services = {
    noctalia-shell = {
      enable = true;
    };
    # hypridle.enable = true;
  };
  programs = {
    niri = {
      enable = true;
    };
    # uwsm.enable = true;
    # hyprland = {
    #   enable = true;
    #   xwayland.enable = true;
    #   withUWSM = true;
    # };
    # iio-hyprland.enable = true;
    # hyprlock.enable = true;
  };
}
