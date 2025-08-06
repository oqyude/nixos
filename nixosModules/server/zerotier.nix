{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    zerotierone = {
      enable = enable;
      joinNetworks = [
        "db64858fedde087e"
      ];
      port = 9993;
    };
  };

  # environment = {
  #   systemPackages = with pkgs; [
  #     zerotierone
  #   ];
  # };
}
