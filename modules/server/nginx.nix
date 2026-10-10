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
      # vtimeline.zeroq.su — Veeam Timeline View. Reverse-proxies the
      # entire vhost to a local Node.js/Express process (managed by
      # systemd as `vtimeline-api` — see modules/server/vtimeline.nix),
      # which serves both the static frontend (public_html/) and the
      # /api/uploads JSON-upload CRUD over a single listener on
      # 127.0.0.1:8000. Authelia forward-auth is wired on `/` so every
      # hit (static OR /api/*) requires a valid session cookie.
      #
      # client_max_body_size 6m matches the server.js body limit
      # (5 MB hard cap). nginx's default 1m would 413 any upload near
      # the cap before the request reached the node process.
      "vtimeline.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8000";
            proxyWebsockets = true;
            extraConfig = ''
              auth_request /authelia;
              auth_request_set $authelia_user $upstream_http_remote_user;
              # Authelia for an anonymous user on a `one_factor`-protected
              # vhost returns 302 + Location to the login UI by default
              # (because nginx forwards Accept: text/html). nginx's
              # auth_request only treats 2xx/4xx as pass/deny, so a bare
              # 302 surfaces to the client as 500 ("auth request
              # unexpected status"). Converting 401 → 302 to the
              # login page handles that case. Authelia returns 401 only
              # when the subrequest advertises Accept: application/json
              # (see the /authelia block below).
              # `$request_uri` is the URI path only — Authelia would
              # then resolve `rd` as relative to its own `authelia_url`
              # and send the user back to `authelia.zeroq.su/<path>`,
              # not `vtimeline.zeroq.su/<path>`, after a successful
              # login. Pass the full origin (scheme + host + path) so
              # Authelia constructs an absolute redirect back to the
              # original vhost.
              error_page 401 =302 https://authelia.zeroq.su/?rd=$scheme://$host$request_uri;
              client_max_body_size 6m;
            '';
          };
          "= /authelia" = {
            extraConfig = ''
              internal;
              proxy_pass http://127.0.0.1:9091/api/authz/forward-auth;
              proxy_set_header X-Original-URL $request_uri;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Method $request_method;
              proxy_set_header X-Forwarded-Uri $request_uri;
              proxy_set_header X-Forwarded-For $remote_addr;
              # Force Authelia to respond with 401 (not 302 + Location) so
              # the error_page 401 =302 rule above can take over. With the
              # default Accept: text/html Authelia sends a 302 with an
              # absolute Location, which auth_request surfaces to the client
              # as 500 ("unexpected status").
              proxy_set_header Accept "application/json";
            '';
          };
        };
      };
      # tty.zeroq.su — web-shell (ttyd) behind Authelia forward-auth.
      # ttyd listens on 127.0.0.1:7681 only (modules/server/ttyd.nix), so
      # nginx is the only ingress. Same auth_request / 401→302 wiring as
      # vtimeline.zeroq.su above — the wildcard rule `*.zeroq.su` in
      # modules/server/authelia.nix already covers this subdomain under
      # `one_factor`, so no policy change is needed.
      "tty.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:7681";
            proxyWebsockets = true;
            extraConfig = ''
              auth_request /authelia;
              auth_request_set $authelia_user $upstream_http_remote_user;
              # Same 401→302 trick as vtimeline.zeroq.su: a bare 302 from
              # Authelia surfaces to the client as a 500 ("auth request
              # unexpected status"), so we rewrite the response status to
              # a 302 pointing at the authelia login UI with an absolute
              # `$scheme://$host$request_uri` so the post-login `rd`
              # lands the user back on tty.zeroq.su, not on
              # authelia.zeroq.su/<path>.
              error_page 401 =302 https://authelia.zeroq.su/?rd=$scheme://$host$request_uri;
            '';
          };
          "= /authelia" = {
            extraConfig = ''
              internal;
              proxy_pass http://127.0.0.1:9091/api/authz/forward-auth;
              proxy_set_header X-Original-URL $request_uri;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Method $request_method;
              proxy_set_header X-Forwarded-Uri $request_uri;
              proxy_set_header X-Forwarded-For $remote_addr;
              # Same Accept-forces-401 trick as vtimeline.zeroq.su — see
              # the comment there for why Authelia's default 302 is
              # harmful here.
              proxy_set_header Accept "application/json";
            '';
          };
        };
      };
      # Authelia login UI — same podman container on 127.0.0.1:9091 as the
      # forward-auth endpoint above, just exposed on a separate vhost so
      # Authelia has a stable absolute URL to redirect users to. Authelia
      # generates internal links against $session.cookies[0].authelia_url,
      # which is set to https://${autheliaFqdn}/ in modules/server/authelia.nix.
      "authelia.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
          proxyWebsockets = true;
        };
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
  # networking.firewall is intentionally unused on sapphira (R1.3):
  # the network boundary is the router, not the host firewall.

  # Note: the previous vtimeline-htpasswd sops declaration lived here. It
  # was removed when authelia replaced nginx's auth_basic (see the vtimeline
  # vhost above). The encrypted file modules/server/secrets/vtimeline-htpasswd.yaml
  # itself was kept untouched per the repo policy of not modifying secrets
  # without explicit owner sign-off; delete it with `sops --version` and
  # `rm` once the cutover is verified.
}
