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
    #../audio/preempt_rt.nix

    inputs.self.nixosModules.additional.musnix # musnix module
    inputs.self.nixosModules.additional.aagl # aagl module
  ];

  #rtnix.kernel.realtime.enable = true;
  #rtnix.tuningProcesses = [ "irq/.*xhci" "irq/.*snd_intel_hda" ];

}
