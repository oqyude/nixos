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
      mediaLocation = "/mnt/immich";
    };
    cloudflared = {
      enable = true;
      tunnels = {
        "e5d66ea5-d6d2-4eef-9b34-82696946ef58" = {
          credentialsFile = "${inputs.zeroq.dirs.server-home}/Credentials/server/cloudflared/e5d66ea5-d6d2-4eef-9b34-82696946ef58.json";
          certificateFile = "${inputs.zeroq.dirs.server-home}/Credentials/server/cloudflared/cert.pem";
          ingress = {
            "zeroq.ru" = {
              service = "http://localhost:2283";
            };
          };
          default = "http_status:404";
        };
      };
    };
  };

  fileSystems."${config.services.immich.mediaLocation}" = {
    device = "${inputs.zeroq.dirs.immich-folder}";
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
      cloudflared
    ];
  };
}
