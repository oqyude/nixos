{
  config,
  inputs,
  pkgs,
  ...
}:
let
  server = "100.64.0.0";
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
        "x.zeroq.su" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:2049";
              proxyWebsockets = true;
            };
            "/subs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
            "/subsjs/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
            "/clash/" = {
              proxyPass = "http://localhost:2096";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "go.bin043120@gmail.com";
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
