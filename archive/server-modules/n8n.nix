{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  storage = xlib.helpers.mkServiceStorage {
    name = "n8n";
    user = "nobody";
    group = "nogroup";
  };
in
{
  services.n8n = {
    enable = false;
    environment = {
      # N8N_USER_FOLDER = lib.mkForce "${sourceDir}";
      N8N_SECURE_COOKIE = "false";
      N8N_PORT = 5678;
    };
    openFirewall = true;
  };

  systemd = storage.systemd;
}
