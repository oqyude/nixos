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
      #       user = "${inputs.zeroq.devices.admin}";
      #       group = "users";
      #       home = "/home/${inputs.zeroq.devices.admin}/.ollama";
      #       models = "${inputs.zeroq.dirs.vetymae-drive}/AI/Ollama/models";
      acceleration = "rocm";
      rocmOverrideGfx = "11.5.0";
    };
  };
  environment.systemPackages = with pkgs; [ lmstudio ];
}
