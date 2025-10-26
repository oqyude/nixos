{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
  };
in
{
  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      dataDir = "${xlib.dirs.services-mnt-folder}/postgresql/${config.services.postgresql.package.psqlSchema}";
    };
    # postgresqlBackup.enable = true;
  };
  
  systemd.tmpfiles.rules = [
    "z ${config.services.postgresql.dataDir} 0760 postgres postgres -"
  ];
}
