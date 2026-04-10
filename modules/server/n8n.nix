{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  services.n8n = {
    enable = true;
    environment = {
      # N8N_USER_FOLDER = lib.mkForce "${xlib.dirs.services-mnt-folder}/n8n";
      N8N_SECURE_COOKIE = "false";
      N8N_PORT = 5678;
    };
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d ${xlib.dirs.services-mnt-folder}/n8n 0755 nobody nogroup -"
    "z ${xlib.dirs.services-mnt-folder}/n8n 0755 nobody nogroup -"
  ];

  fileSystems."/var/lib/n8n" = {
    device = "${xlib.dirs.services-mnt-folder}/n8n";
    fsType = "none";
    options = [
      "bind"
      "nofail"
    ];
  };
}
