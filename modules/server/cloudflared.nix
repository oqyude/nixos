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
          credentialsFile = "${inputs.zeroq.dirs.server-home}/Credentials/server/cloudflared/immich.json";
          ingress = {
            "immich.zeroq.ru" = {
              service = "http://localhost:2283";
            };
          };
          warp-routing.enabled = true;
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
