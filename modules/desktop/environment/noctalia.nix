{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];
  environment.systemPackages = with pkgs; [
    # inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  services.noctalia-shell = {
    enable = true;
    # target = "my-hyprland-session.target";
  };
}
