{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    postgresql = {
      enable = lib.mkDefault true;
    };
    immich = {
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = false;
      mediaLocation = "${inputs.zeroq.dirs.immich-folder}";
    };
  };

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  environment = {
    systemPackages = with pkgs; [
      immich-cli
    ];
  };
}
