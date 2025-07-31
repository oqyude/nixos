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
      package = pkgs.ollama;
      user = "ollama"; #"${inputs.zeroq.devices.admin}";
      group = "ollama";
      #       home = "/home/${inputs.zeroq.devices.admin}/.ollama";
      #       models = "${inputs.zeroq.dirs.vetymae-drive}/AI/Ollama/models";
      acceleration = "rocm";
      #rocmOverrideGfx = "11.5.0";
    };
  };

  users = {
    ollama = {
      ollama.isSystemUser = true;
    };
  };

  environment.systemPackages = with pkgs; [ lmstudio ];
}
