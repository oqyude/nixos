{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    cloudflared = {
      enable = true;

      certificateFile = "${inputs.zeroq.dirs.server-home}/Credentials/server/cloudflared/cert.pem";
      tunnels = {
        "e5d66ea5-d6d2-4eef-9b34-82696946ef58" = {
          credentialsFile = "${inputs.zeroq.dirs.server-credentials}/cloudflared/immich.json";
          warp-routing.enabled = false;
          originRequest = {
            tlsTimeout = "15s";
            tcpKeepAlive = "30s";
            noHappyEyeballs = false;
            keepAliveTimeout = "1m30s";
            connectTimeout = "1m";
          };
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
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      cloudflared
    ];
  };
}
