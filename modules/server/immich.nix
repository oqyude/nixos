{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  new = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
  };
in
{
  services = {
    immich = {
      enable = true;
      package = new.immich;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = true;
      mediaLocation = "${xlib.dirs.services-mnt-folder}/immich";
    };
  };

  systemd.tmpfiles.rules = [
    "z ${config.services.immich.mediaLocation} 0755 immich immich -"
  ];

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
