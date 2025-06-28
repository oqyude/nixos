{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    stateVersion = lib.mkDefault "25.05";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    enableNixpkgsReleaseCheck = false;
  };
}
