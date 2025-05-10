{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment = {
    systemPackages = with pkgs; [
      #wineWowPackages.waylandFull
      wineWowPackages.stagingFull
      #wineWowPackages.fonts
      dxvk
    ];
    sessionVariables = {
      WINEARCH = "win64";
    };
  };
}
