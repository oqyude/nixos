{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  storage = xlib.helpers.mkServiceStorage {
    name = "samba";
    user = "root";
    group = "root";
  };
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

  systemd = storage.systemd // {
    # The samba file server is the unit `samba-smbd` (nixpkgs names it that
    # way; there is NO unit called `samba`). `systemd.services.samba` would
    # render a phantom unit with no ExecStart → systemd refuses to start it
    # (ADR-0004).
    #
    # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
    # directive and is ignored by systemd in `[Service]` (T4/R1.2).
    #
    # mkIf guard (2026-10-30): without it, turning the file server off
    # (services.samba.enable = false) left the unit defined with ONLY
    # `unitConfig` and no ExecStart — the very phantom ADR-0004 describes.
    # systemd then refuses to start it ("Service has no ExecStart=… Refusing.").
    # It bit us for real while proving modules/server/samba-ad.nix: the AD DC
    # and the file server cannot both hold TCP/445, so the file server has to
    # be switchable off. With services.samba.enable = true (every host today)
    # this guard changes nothing.
    services."samba-smbd" = lib.mkIf config.services.samba.enable {
      unitConfig = xlib.helpers.mkStorageGuard xlib;
    };
  };
}
