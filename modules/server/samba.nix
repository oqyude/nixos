{
  config,
  inputs,
  pkgs,
  xlib,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/samba";
  targetDir = "/var/lib/samba";
in
{
  services = {
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      hostname = "sapphira";
      discovery = true;
    };
    samba = {
      enable = true;
      # package = pkgs.samba4Full;
      nmbd = {
        enable = true;
      };
      settings = {
        global = {
          "invalid users" = [ ];
          "passwd program" = "/run/wrappers/bin/passwd %u";
          security = "user";
        };
        nixos = {
          "path" = "/etc/nixos";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "${xlib.device.username}";
          "guest ok" = "no";
          "writable" = "yes";
          "create mask" = 755;
          "directory mask" = 755;
          "force user" = "${xlib.device.username}";
          "force group" = "users";
        };
        root = {
          "path" = "/";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "${xlib.device.username}";
          "guest ok" = "no";
          "writable" = "yes";
          #"create mask" = 0644;
          #"directory mask" = 0644;
          "force user" = "root";
          "force group" = "root";
        };
        "${xlib.device.username}" = {
          "path" = "${xlib.dirs.server-home}";
          "browseable" = "yes";
          "read only" = "no";
          "valid users" = "${xlib.device.username}";
          "guest ok" = "no";
          "writable" = "yes";
          "create mask" = 700;
          "directory mask" = 700;
          "force user" = "${xlib.device.username}";
          "force group" = "users";
        };
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d ${sourceDir} 0755 root root -"
      "z ${sourceDir} 0755 root root -"
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
