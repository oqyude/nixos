{
  config,
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/n8n";
  targetDir = "/var/lib/n8n";
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

  systemd = {
    tmpfiles.rules = [
      "d ${sourceDir} 0755 nobody nogroup -"
      "z ${sourceDir} 0755 nobody nogroup -"
    ];
    mounts = [
      {
        enable = true;
        options = "bind,x-systemd.automount,nofail";
        requires = [ "local-fs.target" ];
        type = "none";
        wantedBy = [ "multi-user.target" ];
        what = "${sourceDir}";
        where = "${targetDir}";
      }
    ];
  };
}
