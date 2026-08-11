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
          DOMAIN = "git.zeroq.su";
          HTTP_PORT = 3000;
        };
        service.DISABLE_REGISTRATION = true;
      };
    };
  };

  systemd.tmpfiles.rules = xlib.helpers.mkTmpDirs {
    dir = config.services.gitea.stateDir;
    mode = "0755";
    user = "gitea";
    group = "gitea";
  };
}
