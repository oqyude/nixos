{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
let
  master = import inputs.nixpkgs-immich {
    system = "x86_64-linux";
  };
in
{
  services = {
    immich = {
      enable = true;
      package = pkgs.immich;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = true;
      mediaLocation = "${xlib.dirs.services-mnt-folder}/immich";
      database = {
        enableVectors = false;
        enableVectorChord = true;
      };
    };
    postgresql.package = pkgs.postgresql_16;
  };

  fileSystems."${config.services.immich.mediaLocation}" = {
    device = "${xlib.dirs.services-folder}/immich";
    options = [
      "bind"
      "nofail"
    ];
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
