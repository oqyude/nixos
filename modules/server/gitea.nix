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
          DOMAIN = "gitea.local";
          HTTP_PORT = 3000;
        };
        service.DISABLE_REGISTRATION = true;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "z ${config.services.gitea.stateDir} 0755 gitea gitea -"
  ];
}
