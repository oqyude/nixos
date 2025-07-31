{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    nextjs-ollama-llm-ui.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      environmentVariables = {
        HCC_AMDGPU_TARGET = "gfx1150"; # used to be necessary, but doesn't seem to anymore
      };
      user = "ollama"; # "${inputs.zeroq.devices.admin}";
      group = "ollama";
      #       home = "/home/${inputs.zeroq.devices.admin}/.ollama";
      #       models = "${inputs.zeroq.dirs.vetymae-drive}/AI/Ollama/models";
      acceleration = "rocm";
      rocmOverrideGfx = "11.5.0";
    };
  };

  services.open-webui.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];
  # users = {
  #   ollama = {
  #     ollama.isSystemUser = true;
  #   };
  # };

  environment.systemPackages = with pkgs; [ lmstudio ];
}
