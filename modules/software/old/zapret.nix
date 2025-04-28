{
  config,
  lib,
  pkgs,
  ...
}:
{
  #   services.zapret = {
  #     enable = true;
  #     httpMode = "full";
  #     udpSupport = true;
  #     udpPorts = [
  #       "50000:65535"
  #     ];
  #     params = [
  #       "--dpi-desync=fake,tamper"
  #       "--dpi-desync-repeats=6"
  #       "--dpi-desync-any-protocol"
  #     ];
  #   };
  #   users.users.oqyude = {
  #     packages = with pkgs; [
  #       zapret
  #     ];
  #   };
}
