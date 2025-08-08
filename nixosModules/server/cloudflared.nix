{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  services = {
    cloudflared = {
      enable = false;
      certificateFile = "${xlib.dirs.server-credentials}/cloudflared/cert.pem";
      tunnels = {
        "58b340ee-e98a-4af9-b786-74600c71f49e" = {
          credentialsFile = "${xlib.dirs.server-credentials}/cloudflared/server.json";
          warp-routing.enabled = true;
          ingress = {
            "immich.zeroq.ru" = {
              service = "http://localhost:2283";
            };
            "nextcloud.zeroq.ru" = {
              service = "http://localhost:10000";
            };
          };
          default = "http_status:404";
        };
        #         "58b340ee-e98a-4af9-b786-74600c71f49e" = {
        #           credentialsFile = "${xlib.dirs.server-credentials}/cloudflared/server.json";
        #           warp-routing.enabled = true;
        #           ingress = {
        #             "nextcloud.zeroq.ru" = {
        #               service = "http://localhost:10000";
        #             };
        #           };
        #           default = "http_status:404";
        #         };
      };
    };
  };

  #   users.users = {
  #     cloudflared = {
  #       group = "cloudflared";
  #       isSystemUser = true;
  #     };
  #   };
  #   users.groups.cloudflared = { };
  #
  #   systemd.services.cloudflared = {
  #     after = [
  #       "network.target"
  #       "network-online.target"
  #     ];
  #     wants = [
  #       "network.target"
  #       "network-online.target"
  #     ];
  #     wantedBy = [ "multi-user.target" ];
  #     serviceConfig = {
  #       ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config=${xlib.dirs.server-credentials}/cloudflared/config.yaml --origincert=${xlib.dirs.server-credentials}/cloudflared/cert.pem --credentials-file=${xlib.dirs.server-credentials}/cloudflared/server.json run";
  #       Group = "root";
  #       User = "root";
  #       Restart = "on-failure";
  #     };
  #   };

  environment = {
    systemPackages = with pkgs; [
      cloudflared
    ];
  };
}
