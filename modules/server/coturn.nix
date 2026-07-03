{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
# let
#   acme-path = "/var/lib/acme";
# in
{
  services.coturn = {
    enable = false;
    realm = "turn.home.arpa";
    # cert = "${acme-path}/turn.home.arpa/fullchain.pem";
    # pkey = "${acme-path}/turn.home.arpa/key.pem";
    use-auth-secret = true;
    static-auth-secret-file = config.sops.secrets.turn-secret.path;
    no-cli = true;
    listening-port = 3478; # TURN
    # tls-listening-port = 5349; # TURNS
    extraConfig = ''
      min-port=49160
      max-port=49200
    '';
  };
  networking.firewall = {
    allowedTCPPorts = [
      3478
      # 5349
    ];
    allowedUDPPorts = [
      3478
    ];
    allowedUDPPortRanges = [
      {
        from = 49160;
        to = 49200;
      }
    ];
  };
  sops.secrets = {
    turn-secret = {
      format = "yaml";
      key = "turn-secret";
      sopsFile = ./secrets/coturn.yaml;
      group = "nextcloud-spreed-signaling";
      owner = "turnserver";
      mode = "0440";
    };
  };
}
