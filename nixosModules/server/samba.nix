{
  config,
  ...
}:
{
  services = {
        samba = {
          enable = true;
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
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 755;
              "directory mask" = 755;
              "force user" = "${config.xlib.device.username}";
              "force group" = "users";
            };
            root = {
              "path" = "/";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              #"create mask" = 0644;
              #"directory mask" = 0644;
              "force user" = "root";
              "force group" = "root";
            };
            "${config.xlib.device.username}" = {
              "path" = "${config.xlib.dirs.server-home}";
              "browseable" = "yes";
              "read only" = "no";
              "valid users" = "${config.xlib.device.username}";
              "guest ok" = "no";
              "writable" = "yes";
              "create mask" = 700;
              "directory mask" = 700;
              "force user" = "${config.xlib.device.username}";
              "force group" = "users";
            };
          };
        };
  };
}
