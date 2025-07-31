{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # services = {
  #   nextjs-ollama-llm-ui.enable = false;
  #   ollama = {
  #     enable = false;
  #     package = pkgs.ollama-rocm;
  #     environmentVariables = {
  #       HSA_OVERRIDE_GFX_VERSION = "11.5.0";
  #       HCC_AMDGPU_TARGET = "gfx1150"; # used to be necessary, but doesn't seem to anymore
  #     };
  #     user = "ollama"; # "${inputs.zeroq.devices.admin}";
  #     group = "ollama";
  #     acceleration = "rocm";
  #     rocmOverrideGfx = "11.5.0";
  #   };
  # };
}
