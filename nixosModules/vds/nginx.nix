{
  config,
  inputs,
  ...
}:
let
  server = "100.64.0.0";
in
{
  services = {
    nginx = {
      enable = false;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "immich.zeroq.ru" = {
          # 31.57.105.253
          listen = [
            {
              addr = "0.0.0.0";
              port = 8443;
              ssl = true;
            }
          ];
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${server}:2283"; # Порт Immich
            proxyWebsockets = true; # Если Immich использует WebSockets
          };
        };
        # "nextcloud.zeroq.ru" = {
        #   addSSL = true;
        #   forceSSL = false;
        #   enableACME = false;
        #   locations."/" = {
        #     proxyPass = "http://${server}:10000"; # Порт Nextcloud
        #     proxyWebsockets = true;
        #   };
        # };
        # "llm.zeroq.ru" = {
        #   addSSL = true;
        #   enableACME = true;
        #   locations."/" = {
        #     proxyPass = "http://atoridu.laxta-platy.ts.net:11111"; # Порт Open WebUI
        #     proxyWebsockets = true;
        #   };
        # };
      };
    };
    # blocky = {
    #   enable = true;
    #   settings = {
    #     ports.dns = 53; # Port for incoming DNS Queries.
    #     upstreams.groups.default = [
    #       "https://dns.quad9.net/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
    #     ];
    #     # For initially solving DoH/DoT Requests when no system Resolver is available.
    #     bootstrapDns = {
    #       upstream = "https://dns.quad9.net/dns-query";
    #       ips = [ "9.9.9.9" ];
    #     };
    #     # Custom DNS entries
    #     customDNS = {
    #       mapping = {
    #         "immich.zeroq.ru" = "100.90.0.0";
    #       };
    #     };
    #   };
    # };
  };
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "go.bin043120@gmail.com";
  #   certs."immich.zeroq.ru" = {
  #     email = "go.bin043120@gmail.com";
  #     dnsProvider = "cloudflare";
  #     dnsResolver = "1.1.1.1";
  #     environmentFile = "${inputs.zeroq-credentials}/accounts/cloudflare.txt";
  #     webroot = null; # Required in my case
  #   };
  # };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
