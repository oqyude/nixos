# https://github.com/musnix/musnix
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
        ###
        boot.kernelModules = [
          "snd-seq"
          "snd-rawmidi"
        ];
        services = {
          pipewire.enable = lib.mkForce false;
          jack = {
            jackd.enable = lib.mkForce true;
            alsa.enable = true;
            loopback.enable = true;
          };
        };
        environment.systemPackages = with pkgs; [
          jack2
          jack_capture
          libjack2
          pavucontrol
          qjackctl
        ];
        musnix = {
          enable = true;
          #ffado.enable = true;
          rtcqs.enable = true;
          kernel.realtime = true;
          kernel.packages = pkgs.linuxPackages_latest_rt;
        };
        ###
      };
    };
  };
}
