{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
# Standard reverse-proxy: HTTP/S termination upstream, backend on the LAN.
# x.zeroq.su is the 3x-ui controller panel — see 3x-ui.nix for the
# /subs/, /subsjs/, /clash/ routing logic.
let
  server = "192.168.1.20";

  mkProxy =
    {
      domain,
      port,
      addSSL ? false,
      extraConfig ? "",
    }:
    {
      name = domain;
      value = {
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${server}:${toString port}";
          proxyWebsockets = true;
        };
      }
      // lib.optionalAttrs (!addSSL) { forceSSL = true; }
      // lib.optionalAttrs addSSL { addSSL = true; }
      // lib.optionalAttrs (extraConfig != "") { inherit extraConfig; };
    };

  bigUploads = "client_max_body_size 5G;";

  sites = [
    {
      domain = "immich.zeroq.su";
      port = 2283;
      addSSL = true;
      extraConfig = bigUploads;
    }
    {
      domain = "kuma.zeroq.su";
      port = 4001;
    }
    {
      domain = "health.zeroq.su";
      port = 19999;
    }
    {
      domain = "git.zeroq.su";
      port = 3000;
    }
    {
      domain = "homebox.zeroq.su";
      port = 7745;
    }
    {
      domain = "flux.zeroq.su";
      port = 6061;
    }
    {
      domain = "navidrome.zeroq.su";
      port = 4533;
      addSSL = true;
    }
    {
      domain = "calibre.zeroq.su";
      port = 8083;
      extraConfig = bigUploads;
    }
    {
      domain = "nix-cache.zeroq.su";
      port = 5000;
      extraConfig = bigUploads;
    }
    {
      domain = "pdf.zeroq.su";
      port = 8446;
      extraConfig = bigUploads;
    }
  ];
in
{
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = (builtins.listToAttrs (map mkProxy sites)) // {
      "nextcloud.private" = {
        forceSSL = false;
        enableACME = false;
        listen = [
          {
            addr = "100.64.0.0";
            port = 10000;
          }
          {
            addr = "192.168.1.20";
            port = 10000;
          }
          {
            addr = "127.0.0.1";
            port = 10000;
          }
        ];
      };
      "office.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
      };
      "pdf.private" = {
        forceSSL = false;
        enableACME = false;
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
          {
            addr = "100.64.0.0";
            port = 8446;
          }
          {
            addr = "192.168.1.20";
            port = 8446;
          }
          {
            addr = "127.0.0.1";
            port = 8446;
          }
        ];
        extraConfig = bigUploads;
      };
      "x.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://${server}:2049";
            proxyWebsockets = true;
          };
          "/subs/" = {
            proxyPass = "http://${server}:2096";
            proxyWebsockets = true;
          };
          "/subsjs/" = {
            proxyPass = "http://${server}:2096";
            proxyWebsockets = true;
          };
          "/clash/" = {
            proxyPass = "http://${server}:2096";
            proxyWebsockets = true;
          };
        };
      };
      "zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        root = pkgs.writeTextDir "index.html" ''
          <!doctype html>
          <html>
          <body>
            <pre>What are you doing here?</pre>
          </body>
          </html>
        '';
        locations."/guest/" = {
          proxyPass = "http://${server}:80";
          proxyWebsockets = true;
        };
      };
      "vetymae.opencodes.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://100.86.62.4:4096";
          proxyWebsockets = true;
        };
      };
      "lamet.opencodes.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://100.106.21.39:6061";
          proxyWebsockets = true;
        };
      };
      "nextcloud.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://${server}:10000";
            proxyWebsockets = true;
          };
          "/whiteboard" = {
            proxyPass = "http://${server}:3002";
            proxyWebsockets = true;
          };
        };
        extraConfig = bigUploads;
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
