{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  specialisation = {
    "rt_kernel" = {
      inheritParentConfig = true;
      configuration = {
        #system.nixos.label = "musnix";
        boot.blacklistedKernelModules = [
          "nvidia"
          "nouveau"
          "nvidia_drm"
          "nvidia_modeset"
        ];
        musnix = {
          enable = true;
          #ffado.enable = true;
          rtcqs.enable = true;
          kernel.realtime = true;
          kernel.packages = lib.mkForce pkgs.linuxPackages_latest_rt;
        };
        #             hardware = {
        #               nvidia = {
        #                 enabled = lib.mkForce false;
        #               };
        #             };
      };
    };
  };
}
