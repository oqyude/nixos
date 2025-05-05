{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{

  hardware = {
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };
}
