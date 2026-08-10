{
  lib,
  xlib,
  ...
}:
{
  services.tailscale.enable = xlib.device.type != "wsl"; # true, if not wsl

  # All real hosts (not the bare "minimal" test config) get OOM protection
  # and a bounded journal.
  services.earlyoom.enable = lib.mkIf (xlib.device.type != "minimal") true;
  services.journald.extraConfig = lib.mkIf (xlib.device.type != "minimal") ''
    SystemMaxUse=512M
  '';
}
