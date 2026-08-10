{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  sourceDir = "${xlib.dirs.services-mnt-folder}/postgresql";
  targetDir = "/var/lib/postgresql";
in
{
  services = {
    postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };
    # postgresqlBackup.enable = true;
  };

  systemd = {
    tmpfiles.rules = [
      "d ${sourceDir} 0760 postgres postgres -"
      "z ${sourceDir} 0760 postgres postgres -"
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
