{
  config,
  lib,
  pkgs,
  inputs,
  xlib,
  ...
}:
# let
#   pkgsn = import inputs.nixpkgs-master { system = "x86_64-linux"; };
# in
{
  services = {
    immich = {
      #package = pkgsn.immich; # inputs.self.packages.x86_64-linux.immich;
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = false;
      mediaLocation = "/mnt/immich";
    };
  };

  fileSystems."${config.services.immich.mediaLocation}" = {
    device = "${xlib.dirs.immich-folder}";
    options = [
      "bind"
      #"uid=1000"
      #"gid=1000"
      #"fmask=0007"
      #"dmask=0007"
      "nofail"
      "x-systemd.device-timeout=0"
    ];
  };

  systemd.tmpfiles.rules = [
    "z /mnt/immich 0755 immich immich -" # beets absolute paths
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
