{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  configDir = "${xlib.dirs.services-mnt-folder}/n8n";
  varDir = "/var/lib/n8n";
in
{
  services.n8n = {
    enable = true;
    environment = {
      # N8N_USER_FOLDER = lib.mkForce "${configDir}";
      N8N_SECURE_COOKIE = "false";
      N8N_PORT = 5678;
    };
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d ${configDir} 0755 nobody nogroup -"
    "z ${configDir} 0755 nobody nogroup -"
  ];

  fileSystems.${varDir} = {
    device = "${configDir}";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };
}
