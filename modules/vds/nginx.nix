{
  config,
  inputs,
  pkgs,
  ...
}:
let
  server = "100.64.0.0";
  # Forward real client IP/host to 3x-ui so it can manage addresses
  # (subscription URLs, logs, geo-rules, fail2ban) as if it shared the
  # host network. With podman bridge networking, the source IP that
  # 3x-ui sees is the bridge gateway instead of the actual client.
  proxyHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  '';
in
{
  users.users.nginx.extraGroups = [ "acme" ];
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "pubray1.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:2049";
              proxyWebsockets = true;
              extraConfig = proxyHeaders;
            };
            "/subs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
              extraConfig = proxyHeaders;
            };
            "/subsjs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
              extraConfig = proxyHeaders;
            };
            "/clash/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
              extraConfig = proxyHeaders;
            };
          };
        };
      };
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
