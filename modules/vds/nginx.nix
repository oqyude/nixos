{
  config,
  inputs,
  pkgs,
  ...
}:
# VDS nginx differs from server's in one key way: port 443 is owned
# by an nginx stream block that does SNI-based TCP routing, not by
# http { server {} } blocks. This lets a single host (pubray1.zeroq.su)
# serve both the 3x-ui panel and an Xray REALITY inbound over TLS,
# sharing the same port.
#
# Routing:
#   pubray1.zeroq.su  → 127.0.0.1:2049  (3x-ui panel; LE cert mounted
#                       into the container terminates TLS)
#   pubrayx1.zeroq.su → 127.0.0.1:15380 (Xray REALITY; Xray sees its
#                       real configured port 443 via DNAT)
#   default           → 127.0.0.1:15380 (REALITY fallback for any
#                       other SNI / IP-direct)
#
# ssl_preread reads SNI from the ClientHello and forwards the rest of
# the TLS stream as-is, so Xray sees a real port-443 connection even
# though podman DNATs it via host:15380.
let
  # Goes inside the auto-generated `stream {}` block (services.nginx.streamConfig).
  # pubray1.zeroq.su → 3x-ui panel; everything else (including any SNI
  # a REALITY client uses, e.g. media.mediavitrina.ru) → Xray.
  streamConfig = ''
    ssl_preread on;

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
  '';
in
{
  users.users.nginx.extraGroups = [ "acme" ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    # ACME only — 443 is owned by the stream block, not by http { server {} }.
    # Don't add forceSSL: it would generate an HTTPS server block that
    # conflicts with the stream listener.
    virtualHosts."pubray1.zeroq.su".enableACME = true;
    # Lands inside the auto-generated `stream {}` block.
    streamConfig = streamConfig;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "oqyude@gmail.com";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
