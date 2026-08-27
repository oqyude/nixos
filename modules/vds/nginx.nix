{
  config,
  inputs,
  pkgs,
  ...
}:
let
  server = "100.64.0.0";
  # TCP-level SNI routing on 443:
  #   pubray1.zeroq.su  → 3x-ui panel (TLS passthrough to 127.0.0.1:2049,
  #                       3x-ui terminates TLS using the cert mounted
  #                       from /var/lib/acme/pubray1.zeroq.su/)
  #   pubrayx1.zeroq.su → Xray REALITY (TLS passthrough to 127.0.0.1:15380,
  #                       which podman DNATs to container:443)
  #   default           → Xray (any other SNI / IP-direct hits the REALITY
  #                       fallback, which is what we want)
  # nginx stream does not inspect TLS — the SNI is read from the ClientHello
  # via ssl_preread, then the entire TCP stream (including the rest of the
  # TLS handshake) is forwarded as-is to the chosen upstream. So Xray sees
  # the client connect on its real configured port (443) even though the
  # host-side port from podman's perspective is 15380.
  streamConfig = ''
    stream {
        ssl_preread on;

        # pubray1.zeroq.su SNI → 3x-ui panel (TLS terminated inside the
        # container using the LE cert mounted from /var/lib/acme/).
        # Everything else (including any sni the REALITY client uses,
        # e.g. media.mediavitrina.ru) → Xray. So a single domain
        # pubray1.zeroq.su serves both panel and Xray — the SNI in the
        # TLS ClientHello disambiguates.
        map $ssl_preread_server_name $sni_backend {
          default            xray;
          pubray1.zeroq.su   panel;
        }

        upstream panel {
          server 127.0.0.1:2049;
        }

        upstream xray {
          server 127.0.0.1:15380;
        }

        server {
          listen 443;
          proxy_pass $sni_backend;
          proxy_timeout 600s;
          proxy_connect_timeout 5s;
        }
    }
  '';
in
{
  users.users.nginx.extraGroups = [ "acme" ];
  services = {
    nginx = {
      enable = true;
      # No virtualHosts.<name>.locations for /, /subs/, /subsjs/, /clash/
      # anymore — port 443 is now owned by the stream block, and the
      # 3x-ui panel serves those paths itself once TLS is forwarded to it.
      # Recommended HTTP options retained (still apply to the port-80
      # ACME server block).
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        # ACME only — nginx owns no HTTP server on 443 anymore. The
        # cert at /var/lib/acme/pubray1.zeroq.su/ is consumed by the
        # 3x-ui container (mounted into /root/cert/) so it can do its
        # own TLS termination on 2049. Don't add forceSSL here: that
        # would generate an HTTPS server block on 443 that conflicts
        # with the stream listener above.
        "pubray1.zeroq.su" = {
          enableACME = true;
        };
      };
      # Top-level nginx.conf snippet — `stream {}` lives outside `http {}`,
      # so it can't go through virtualHosts / appendHttpConfig. The NixOS
      # nginx module exposes appendConfig for this.
      appendConfig = streamConfig;
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "oqyude@gmail.com";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}