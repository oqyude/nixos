{ inputs, ... }@flakeContext:
{
  config,
  ...
}:
{
  imports = [
    #./hardware/fingerprint.nix

    inputs.self.nixosModules.hardware.fingerprint # fingerprint module
    #inputs.self.nixosModules.additional.musnix # musnix module
    #inputs.self.nixosModules.additional.aagl # aagl module
  ];
}
