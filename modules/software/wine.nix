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
      wineWowPackages.stagingFull
      wineWowPackages.fonts
      dxvk
    ];
    sessionVariables = {
      WINEARCH = "win64";
    };
  };
}
