{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    immich = {
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = true;
      mediaLocation = "${xlib.dirs.services-mnt-folder}/immich";
    };
  };

  systemd = {
    tmpfiles.rules = [
      (xlib.helpers.mkTmpfile "z" config.services.immich.mediaLocation "0755" "immich" "immich")
    ];
    # nixpkgs names the immich backend unit `immich-server`; there is NO unit
    # called `immich`. `systemd.services.immich` would render a phantom unit
    # with no ExecStart → systemd refuses to start it (ADR-0004).
    #
    # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
    # directive and is ignored by systemd in `[Service]` (T4/R1.2).
    services."immich-server".unitConfig = xlib.helpers.mkStorageGuard xlib;
  };

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
