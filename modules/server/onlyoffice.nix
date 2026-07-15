{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  previous = import inputs.nixpkgs-master {
    system = "x86_64-linux";
    config.allowUnfree = true;
    config.allowUnfreePredicate = true;
  };
in
{
  services.onlyoffice = {
    enable = true;
    # package = previous.onlyoffice-documentserver;
    hostname = "office.home.arpa";
    port = 8090;
    allowLocalConnections = true;
    wopi = true;
    jwtSecretFile = config.sops.secrets.onlyoffice-jwt.path;
    securityNonceFile = config.sops.secrets.onlyoffice-nonce.path;
  };
  sops.secrets = {
    onlyoffice-nonce = {
      format = "yaml";
      key = "nonce";
      sopsFile = ./secrets/onlyoffice.yaml;
      owner = "onlyoffice";
      group = "onlyoffice";
      mode = "0650";
    };
    onlyoffice-jwt = {
      format = "yaml";
      key = "jwt";
      sopsFile = ./secrets/onlyoffice.yaml;
      owner = "onlyoffice";
      group = "onlyoffice";
      mode = "0650";
    };
  };
}
