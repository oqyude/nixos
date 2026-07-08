{
  config,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      hostname = "sapphira.home.arpa";
      discovery = true;
    };
    samba = {
      enable = true;
      package = pkgs.samba4Full;
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

  systemd.tmpfiles.rules = [
    "d ${xlib.dirs.services-mnt-folder}/samba 0755 root root -"
    "z ${xlib.dirs.services-mnt-folder}/samba 0755 root root -"
  ];

  fileSystems = {
    "/var/lib/samba" = {
      device = "${xlib.dirs.services-mnt-folder}/samba";
      fsType = "none";
      options = [
        "bind"
        "nofail"
      ];
    };
  };
}
