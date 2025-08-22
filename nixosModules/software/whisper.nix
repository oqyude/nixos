{
  config,
  lib,
  pkgs,
  xlib,
  ...
}:
{
  environment.systemPackages = [
    pkgs.openai-whisper
  ];
  nixpkgs.config.rocmSupport = true;
  nixpkgs.config.cudaSupport = false;
  hardware.amdgpu.opencl.enable = true;
  hardware.graphics.extraPackages = with pkgs.rocmPackages; [ clr clr.icd ];
}
