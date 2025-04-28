{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  #qt = {
  #  enable = true;
  #  platformTheme = "kde6";
  #};
  environment = {
    plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      elisa
      kwrited
    ];
  };
}
