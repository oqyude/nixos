{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  musnix = {
    enable = true;
    #ffado.enable = true;
    rtcqs.enable = true;
    kernel.realtime = true;
    kernel.packages = pkgs.linuxPackages_latest_rt;
  };
}
