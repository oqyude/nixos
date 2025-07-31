{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    nextjs-ollama-llm-ui.enable = false;
    open-webui = {
      enable = true;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://127.0.0.1:1234";
        WEBUI_AUTH = "False"; # Disable authentication
      };
    };
    ollama = {
      enable = false;
      package = pkgs.ollama-rocm;
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "11.5.0";
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
