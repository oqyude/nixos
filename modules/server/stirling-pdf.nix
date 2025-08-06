{
  config,
  lib,
  ...
}:
# let
#   fix = import inputs.nixpkgs-last-unstable {
#     system = "x86_64-linux";
#     config.allowUnfree = true;
#   }; # temp
# in
lib.mkIf (config.xlib.device.type == "server") {
  services.stirling-pdf = {
    enable = true;
    environment = {
      SERVER_PORT = 6060;
    };
  };
}
