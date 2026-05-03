{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    nix-serve = {
      enable = true;
      openFirewall = true;
      port = 5000;
      bindAddress = "0.0.0.0";
      secretKeyFile = config.sops.secrets.private-key.path;
    };
  };
  sops.secrets = {
    private-key = {
      key = "private-key";
      sopsFile = ./secrets/nix-serve.yaml;
      mode = "0600";
    };
  };
}
