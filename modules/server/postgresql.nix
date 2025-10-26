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
      # dataDir = "${xlib.dirs.services-mnt-folder}/postgresql";
    };
    # postgresqlBackup.enable = true;
  };
  
  fileSystems."${config.services.postgresql.dataDir}" = {
    device = "${xlib.dirs.services-mnt-folder}/postgresql";
    options = [
      "bind"
      "nofail"
    ];
  };

  systemd.tmpfiles.rules = [
    "z ${xlib.dirs.services-mnt-folder}/postgresql 0760 postgres postgres -"
    # "z ${config.services.postgresql.dataDir} 0760 postgres postgres -"
  ];
}
