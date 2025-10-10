{
  config,
  inputs,
  pkgs,
  ...
}:
let
  xraySettings = {
    log = {
      loglevel = "warning";
    };
    inbounds = [
      {
        port = 8443;
        protocol = "vless";
        settings = {
          clients = [
            {
              id = config.sops.secrets.xray_uuid.path;
              flow = "xtls-rprx-vision";
            }
          ];
          decryption = "none";
        };
        streamSettings = {
          network = "tcp";
          security = "reality";
          realitySettings = {
            dest = "cloudflare.com:443";
            serverNames = [
              "cloudflare.com"
            ];
            privateKey = config.sops.secrets.xray_private-key.path;
            shortIds = [
              "0a381e1fa219"
              "be0ce04754dc"
              "41beec74f4bc"
            ];
          };
        };
        sniffing = {
          enabled = true;
          destOverride = [
            "http"
            "tls"
          ];
        };
      }
    ];
    outbounds = [
      {
        protocol = "freedom";
        tag = "direct";
      }
      {
        protocol = "blackhole";
        tag = "block";
      }
    ];
  };
in
{
  services.xray = {
    enable = true;
    settings = xraySettings;
  };

  networking.firewall = {
    allowedTCPPorts = [ 8443 ];
    allowedUDPPorts = [ 8443 ];
  };

  environment.systemPackages = [ pkgs.xray ];

  sops.secrets = {
    xray_uuid = {
      key = "uuid";
      mode = "0444";
      format = "yaml";
      sopsFile = ./secrets/xray.yaml;
    };
    xray_private-key = {
      key = "private-key";
      mode = "0444";
      format = "yaml";
      sopsFile = ./secrets/xray.yaml;
    };
  };
}
