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
      domain = "tape-rotation.zeroq.su";
      port = 5174;
    }
    # NOTE: open.zeroq.su is intentionally NOT in this `sites` list —
    # mkProxy hard-codes ${server} = 192.168.1.20, but the Open WebUI
    # container binds to 127.0.0.1:8080 only (loopback, see
    # modules/containers/open-webui.nix). The vhost is added directly
    # to `virtualHosts` below, alongside x.zeroq.su (3x-ui panel,
    # same loopback-only pattern).
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
      # vtimeline.zeroq.su — stub behind HTTP basic auth.
      # Credentials are pulled from sops (format = yaml, key = "passwords"),
      # file content is htpasswd-format (one "user:hash" per line).
      # Empty file = 401 for everyone until somebody populates the secret:
      #   sops modules/server/secrets/vtimeline-htpasswd.yaml
      #   htpasswd -nbB <login> <password> | sed 's/:$//'
      "vtimeline.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        root = pkgs.writeTextDir "index.html" "<!doctype html><html><body>Nothing here yet.</body></html>";
        extraConfig = ''
          auth_basic "vtimeline";
          auth_basic_user_file ${config.sops.secrets.vtimeline-htpasswd.path};
        '';
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
            proxyPass = "http://127.0.0.1:2049";
            proxyWebsockets = true;
          };
          "/subs/" = {
            proxyPass = "http://127.0.0.1:2096";
            proxyWebsockets = true;
          };
          "/subsjs/" = {
            proxyPass = "http://127.0.0.1:2096";
            proxyWebsockets = true;
          };
          "/clash/" = {
            proxyPass = "http://127.0.0.1:2096";
            proxyWebsockets = true;
          };
        };
      };
      # Open WebUI — same loopback-only pattern as x.zeroq.su above.
      # The container listens on 127.0.0.1:8080 (modules/containers/open-webui.nix),
      # so we proxy_pass to 127.0.0.1, not the LAN IP. The two extra
      # directives are required by the upstream HTTPS docs:
      # proxy_buffering off for SSE streaming (markdown in chat breaks
      # under the default `proxy_buffering on` from recommendedProxySettings),
      # and a 300 s read timeout for long LLM completions.
      "open.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_buffering off;
          proxy_read_timeout 300s;
        '';
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
      # sapphira itself: opencode web runs as a systemd user service
      # (programs.opencode.web.enable in home/modules/opencode.nix) on
      # 127.0.0.1:4096 with --hostname 0.0.0.0.
      "opencode.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:4096";
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

  # htpasswd file for vtimeline.zeroq.su basic auth.
  # Source layout (per modules/server/secrets/vtimeline-htpasswd.yaml):
  #   passwords: |
  #     <user>:<bcrypt-or-apr1-hash>
  # sops-nix extracts the `passwords` key as the only decrypted content.
  # The resulting file is consumed by nginx via auth_basic_user_file.
  sops.secrets.vtimeline-htpasswd = {
    format = "yaml";
    key = "passwords";
    sopsFile = ./secrets/vtimeline-htpasswd.yaml;
    owner = "nginx";
    group = "nginx";
    mode = "0640";
  };
}
