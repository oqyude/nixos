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
    name = "postgresql";
    user = "postgres";
    group = "postgres";
    mode = "0760";
  };
in
{
  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };
    # postgresqlBackup.enable = true;
  };

  systemd = storage.systemd // {
    # `unitConfig` → `[Unit]`: `ConditionPathIsMountPoint` is a unit-level
    # directive and is ignored by systemd in `[Service]` (T4/R1.2).
    services.postgresql.unitConfig = xlib.helpers.mkStorageGuard xlib;
  };
}
