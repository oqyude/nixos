{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../hardware/fingerprint.nix

    inputs.self.nixosModules.additional.musnix # musnix module
    inputs.self.nixosModules.additional.aagl # aagl module
  ];
}
