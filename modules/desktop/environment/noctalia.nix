{
  config,
  lib,
  pkgs,
  ...
}:
{
  # environment.systemPackages = with pkgs; [
  #   inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  #   # ... maybe other stuff
  # ];
}
