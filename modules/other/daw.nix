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
      # yabridge
      wineWowPackages.yabridge
      yabridge
      yabridgectl

      # JACK Control
      qjackctl
    ];
  };

}
