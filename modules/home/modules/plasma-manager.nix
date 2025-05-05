{ inputs, ... }@flakeContext:
{
  config,
  pkgs,
  ...
}:
{
  programs = {
    plasma = {
      enable = true;
    };
  };
}
