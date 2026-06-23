{
  config,
  inputs,
  ...
}:
# let
#   pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
# in
{
  services.bentopdf = {
    enable = true;
    domain = "pdf.home.arpa";
    nginx = {
      enable = true;
      # virtualHost = {
      #   forceSSL = true;
      #   enableACME = true;
      # };
    };
    # package = pkgs-stable.bentopdf;
  };
}
