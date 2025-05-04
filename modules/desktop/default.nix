{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    #./environment/kde.nix
    #./environment/gnome.nix
    ./environment/budgie.nix
  ];
  programs = {
    xwayland.enable = true;
    dconf.enable = true;
  };
  services = {
    xserver = {
      enable = true;
      #       videoDrivers = [
      #         "amdgpu"
      #         "nvidia"
      #       ];
      xkb = {
        layout = "us,ru";
        variant = "";
        options = "grp:alt_shift_toggle";
      };
    };
    libinput = {
      enable = true;
      mouse = {
        accelProfile = "flat";
      };
      touchpad = {
        accelProfile = "flat";
      };
    };
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
