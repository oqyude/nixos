{
  config,
  inputs,
  ...
}:
{
  services.bentopdf = {
    enable = true;
    domain = "pdf.private";
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
