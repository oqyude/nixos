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
      #mediaLocation = "${inputs.zeroq.dirs.immich-folder}";
    };
  };

  # immich
  # fileSystems."${config.services.immich.mediaLocation}" = {
  #   device = "${inputs.zeroq.dirs.immich-folder}";
  #   options = [
  #     "bind"
  #     # "uid=1000"
  #     # "gid=1000"
  #     # "fmask=0007"
  #     # "dmask=0007"
  #     "nofail"
  #     "x-systemd.device-timeout=0"
  #   ];
  # };

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
