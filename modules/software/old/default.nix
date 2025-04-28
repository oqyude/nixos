{ inputs, ... }@flakeContext:
{
  pkgs,
  config,
  libs,
  ...
}:
{
#   disabledModules = [ "services/networking/zapret.nix" ]; # необходимо если версия nixpkgs новее 5a5c04d
#
#   imports = [ ./zapret-service.nix ];
#
#   services.zapret = {
#     enable = true;
#     udpSupport = true;
#     configureFirewall = true;
#     udpPorts = [
#       "50000:50099"
#       "1234"
#     ];
#     params = [
#         "--dpi-desync=fake,tamper"
#         "--dpi-desync-repeats=6"
#         "--dpi-desync-any-protocol"
#     ];
#   };
}
