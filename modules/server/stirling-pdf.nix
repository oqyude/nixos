{
  config,
  inputs,
  ...
}:
let
  pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
in
{
  services.stirling-pdf = {
    enable = false;
    package = pkgs-stable.stirling-pdf;
    environment = {
      SERVER_PORT = 6060;
    };
  };
}
