{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../hardware/fingerprint.nix


  ];
    #../plugins/musnix.nix
    #../plugins/aagl.nix
}
