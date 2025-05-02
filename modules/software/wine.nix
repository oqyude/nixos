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
    ];
    sessionVariables = {
      WINEARCH = "win64";
    };
  };
}
