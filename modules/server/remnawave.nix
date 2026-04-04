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
    postgresql = {
      ensureDatabases = [ "remnawave" ];
      ensureUsers = [
        {
          name = "remnawave";
          ensureDBOwnership = true;
        }
      ];
    };
  };
  systemd.services.remnawave-db-init = {
    description = "Initialize Remnawave DB user";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script = ''
      PASSWORD=$(cat ${config.sops.secrets.postgresql-password.path})
      ${pkgs.postgresql}/bin/psql -v ON_ERROR_STOP=1 <<EOF
      DO \$\$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='remnawave') THEN
            EXECUTE format('ALTER ROLE remnawave WITH PASSWORD %L', '$PASSWORD');
        END IF;
      END
      \$\$ LANGUAGE plpgsql;
      EOF
    '';
    wantedBy = [ "multi-user.target" ];
  };
  sops.secrets = {
    postgresql-password = {
      format = "yaml";
      key = "postgresql-password";
      sopsFile = ./secrets/remnawave.yaml;
      owner = "postgres";
      group = "postgres";
      mode = "0650";
    };
  };
}
