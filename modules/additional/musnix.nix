{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  musnix.enable = true;
}
