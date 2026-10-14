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
    gitea = {
      enable = true;
      stateDir = "${xlib.dirs.services-mnt-folder}/gitea";
      appName = "ZeroQ Gitea Service";
      settings = {
        server = {
          # nixpkgs-unstable removed `DOMAIN` — must use the full public URL
          # in `ROOT_URL` instead. External entry is HTTPS via nginx with
          # ACME (modules/server/nginx.nix:53), so scheme is https, no port.
          ROOT_URL = "https://git.zeroq.su/";
          HTTP_PORT = 3000;
        };
        service.DISABLE_REGISTRATION = true;
        # Enable Gitea Actions (CI/CD). gitea-runner.nix provides the runner
        # service; this flag only turns on the server-side action handlers.
        actions.ENABLED = true;
      };
    };
  };

  systemd = {
    tmpfiles.rules = xlib.helpers.mkTmpDirs {
      dir = config.services.gitea.stateDir;
      mode = "0755";
      user = "gitea";
      group = "gitea";
    };
    services.gitea.serviceConfig = xlib.helpers.mkStorageGuard xlib;
  };
}
