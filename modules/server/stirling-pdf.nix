{
  config,
  lib,
  pkgs,
  ...
}:
# let
#   customPackage = pkgs.stirling-pdf.overrideAttrs (oldAttrs: {
#     src = pkgs.fetchFromGitHub {
#       owner = "Stirling-Tools";
#       repo = "Stirling-PDF";
#       rev = "v1.1.1";
#       sha256 = "0sphh65fdccnajdby9idy5w4zhcnxzzppv2d7zdz203d0lqs6hky";
#     };
#     version = "1.1.1";
#   });
# in
lib.mkIf (config.xlib.device.type == "server") {
  services.stirling-pdf = {
    enable = true;
    #package = customPackage;
    environment = {
      SERVER_PORT = 6060;
    };
  };
}
