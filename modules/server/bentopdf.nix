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
    domain = "bentopdf.local";
    nginx.enable = true;
    # package = pkgs-stable.bentopdf;
  };
}
