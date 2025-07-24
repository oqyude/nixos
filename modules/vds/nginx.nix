{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
        "vless-sub" = {

          serverName = "${inputs.zeroq.devices.vds.hostname}.latxa-platy.ts.net";
          listen = [
            {
              addr = "${inputs.zeroq.devices.vds.hostname}.latxa-platy.ts.net"; # Tailscale IP вашего VDS
              port = 44444;
              ssl = false;
            }
            {
              addr = "${inputs.zeroq.devices.vds.hostname}.latxa-platy.ts.net"; # Tailscale IP вашего VDS
              port = 44443;
              ssl = true;
            }
          ];
          root = "${inputs.zeroq-credentials.paths.vless-subs.root}"; # "${inputs.zeroq-credentials}/services/xray/subs";
          locations."/" = {
            extraConfig = ''
              if ($scheme = http) {
                return 301 https://$host:44443$request_uri;
              }
            '';
          };
          enableACME = true;
          forceSSL = true; # Принудительно HTTPS

        };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "oqyude@gmail.com"; # Укажите ваш email
    certs."${inputs.zeroq.devices.vds.hostname}.latxa-platy.ts.net" = {
      dnsProvider = null; # Tailscale hostname не требует DNS-проверки, если используем HTTP-01
      webroot = "/var/lib/acme/acme-challenge";
    };
  };
  networking.firewall.allowedTCPPorts = [
    44443
    44444
    80
  ];
}
