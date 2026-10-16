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
              # Never forward the client request body to the auth
              # subrequest. nginx relays the original Content-Length to
              # /authelia but does not relay the body itself, so Authelia
              # blocks waiting for bytes that never arrive and finally
              # answers 408 — a status `auth_request` cannot classify, so
              # nginx reports it to the client as 500 + an HTML error
              # page. Every bodied POST (JSON upload, zip ingest) died
              # this way while plain GETs worked, which is why the page
              # loaded fine but uploads failed with "Server returned
              # non-JSON". Clearing the body and Content-Length makes
              # Authelia authorise on the forwarded headers alone, which
              # is all forward-auth needs. Verified on a reproduction
              # bench: bodied POSTs went 500 (HTML, 6 s timeout) -> 201
              # (JSON, ~10 ms).
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
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
              # Never forward the client request body to the auth
              # subrequest. nginx relays the original Content-Length to
              # /authelia but does not relay the body itself, so Authelia
              # blocks waiting for bytes that never arrive and finally
              # answers 408 — a status `auth_request` cannot classify, so
              # nginx reports it to the client as 500 + an HTML error
              # page. Every bodied POST (JSON upload, zip ingest) died
              # this way while plain GETs worked, which is why the page
              # loaded fine but uploads failed with "Server returned
              # non-JSON". Clearing the body and Content-Length makes
              # Authelia authorise on the forwarded headers alone, which
              # is all forward-auth needs. Verified on a reproduction
              # bench: bodied POSTs went 500 (HTML, 6 s timeout) -> 201
              # (JSON, ~10 ms).
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
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
      # engipy.zeroq.su — FastAPI + SBERT webapp (подбор ГЭСН по ВОР).
      #
      # Vhost был вынесен в modules/server/engipy-frontend.nix
      # (sapphira-стиль, см. комментарий там). nginx-only изменения,
      # включая Authelia forward-auth и static SPA-fallback, живут
      # в том модуле и активируются через host.engipy-frontend.enable.
      # herdr.zeroq.su — web UI for the herdr orchestrator (devswha/herdr-web-ui,
      # MIT, 970★). herdr itself has no HTTP surface (only JSON-RPC over a
      # per-UID Unix socket; see home/modules/herdr.nix for the design
      # context). The webui is provided by the `devswha/herdr-web-ui` herdr
      # plugin, which spawns a Bun-based HTTP+WebSocket server on
      # 127.0.0.1:7317 as a herdr startup hook. Without the plugin installed
      # this vhost 502s; the plugin install is `herdr plugin install
      # devswha/herdr-web-ui` (one shot, then the plugin's update mechanism
      # takes over; the user is expected to handle it — see
      # https://herdrweb.dev/ for the install guide and Tailscale pairing).
      #
      # NO authelia here. herdr-web-ui's CSRF check (sameOrigin in
      # server/machine-security.ts:18-46) compares the browser's
      # `Origin: https://herdr.zeroq.su` against `new URL(request.url).origin`,
      # and `request.url` for a proxy_pass is `http://127.0.0.1:7317/...`
      # — the function does NOT read X-Forwarded-Host, only request.url +
      # x-forwarded-proto. Every cross-origin POST through this vhost
      # would therefore return 403 `invalid_origin`. Setting `Host $host`
      # makes the right Host header reach the Bun server but does not
      # change request.url, so the sameOrigin check still fails. There is
      # no env var or config flag in the Bun server to opt into
      # "trust this proxy" mode (verified by reading server/index.ts and
      # the PROXY_HEADERS table in server/access.ts:105).
      #
      # Auth model: the herdr_web_token cookie / Authorization: Bearer
      # header is the only gate. The token is 64 hex chars (256 bits of
      # entropy), kept at /home/oqyude/.config/herdr/plugins/config/
      # devswha.herdr-web-ui/env mode 0600. Brute-force is rate-limited
      # by the per-IP and shared-proxy budgets in server/auth.ts
      # (AUTH_FAILURE_BUDGET=5, AUTH_BACKOFF_MS=1_000, doubling up to
      # 60 s, 1024-entry LRU). An unauthenticated visitor sees only
      # the SPA's "enter token" / "enter code" screen — the Bun server
      # rejects every /api/* except the three gate endpoints with
      # 401+JSON until a valid token is presented. To bring Authelia
      # back in front, the upstream Bun server needs a `sameOrigin`
      # patch that reads X-Forwarded-Host (fork + plugin link) — the
      # same-origin check assumes direct loopback or Tailscale serve,
      # both of which give request.url a host that matches the browser.
          "herdr.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          # Static assets served by the Bun server (manifest, service
          # worker, favicon, bundled JS/CSS under /assets/). A regex
          # match here keeps the PWA manifest and service worker on
          # the vhost rather than the `/` prefix location, so the
          # browser can fetch them before any cookie is set. There is
          # no auth_request or any other gate — the Bun server enforces
          # the herdr_web_token on every /api/* and on the SPA shell
          # itself.
          #
          # CRITICAL: do NOT add `proxy_set_header Host $host;`,
          # `X-Forwarded-Proto $scheme;` or `X-Forwarded-Host $host;`
          # in this extraConfig. The NixOS module's
          # `services.nginx.recommendedProxySettings = true` already
          # appends an `include
          # ...-nginx-recommended-proxy_set_header-headers.conf;` to
          # every proxy location; that include sets the same three
          # headers. nginx's `proxy_set_header` REPLACES the inherited
          # value in the same scope, so the include's `proxy_set_header
          # X-Forwarded-Host $host;` would normally override ours — but
          # because the include is appended AFTER our extraConfig in
          # the generated location, BOTH directives end up active and
          # nginx sends the header twice (`herdr.zeroq.su, herdr.zeroq.su`).
          # The Bun server's sameOrigin() then sees the comma-joined
          # value, fails to parse it as a host, and returns 403 on
          # every cross-origin POST. The same trap applies to
          # `recommendedProxySettings` for every other vhost on this
          # host; nothing else sets X-Forwarded-* explicitly in extraConfig.
          "~ ^/(manifest\\.webmanifest|sw\\.js|favicon\\.ico|assets/.*)$" = {
            proxyPass = "http://127.0.0.1:7317";
          };
          # Everything else: the SPA shell (`/`) and every /api/* call
          # that requires auth. `proxyWebsockets = true` upgrades the
          # `/ws` SSE feed and the chat WebSocket from the Bun server.
          # Same header caveat as the regex location above: the
          # `recommendedProxySettings` include already sets Host,
          # X-Forwarded-Proto, X-Forwarded-Host correctly; the patch in
          # server/machine-security.ts (applied in-place on sapphira)
          # trusts those headers, so the sameOrigin check lets the
          # browser POST /api/auth and the cookie gets set.
          "/" = {
            proxyPass = "http://127.0.0.1:7317";
            proxyWebsockets = true;
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
      # vetymae (Windows 11, 192.168.1.100) — opencode web, запускается
      # алиасом `oc-serve` из Windows ~/.bashrc (`opencode serve --hostname
      # 0.0.0.0 --port 4096`). Аутентификация включена через
      # OPENCODE_SERVER_PASSWORD из того же .bashrc, поэтому апстрим отвечает
      # 401 без пароля — это ожидаемо, не поломка.
      #
      # Upstream указывает на LAN, а не на 100.86.62.4 (Tailscale), потому
      # что tailscaled на vetymae застрял в NoState с обнулённым
      # PrivateNodeKey: узел виден в tailnet как online, но не принимает
      # ни одного пакета (проверено с двух узлов — sapphira и otreca —
      # и по 22, и по 4096). Рестарт службы Tailscale не помогает, нужен
      # интерактивный `tailscale up` на самом хосте. Вернуться на tailnet
      # стоит только после этого.
      "vetymae.opencodes.zeroq.su" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://192.168.1.100:4096";
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
