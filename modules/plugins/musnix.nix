{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  musnix.enable = true;
}
