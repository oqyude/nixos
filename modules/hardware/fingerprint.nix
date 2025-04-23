{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
    services = {
        fprintd = {
            enable = true;
            tod.enable = true;
            tod.driver = pkgs.libfprint-2-tod1-goodix;
        };
    };

    # start on boot
    systemd.services.fprintd = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "simple";
    };
}
