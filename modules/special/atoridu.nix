{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware/fingerprint.nix
  ];
}
