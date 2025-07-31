{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  last-stable = import inputs.nixos { system = "x86_64-linux"; }; # temp
in
{
  services = {
    open-webui = {
      enable = true;
      #package = last-stable.open-webui;
      host = "0.0.0.0";
      port = 11111;
      openFirewall = true;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OPENAI_API_BASE_URL = "http://192.168.1.100:1234/v1";
        #OLLAMA_API_BASE_URL = "http://127.0.0.1:1234";
        #WEBUI_AUTH = "False"; # Disable authentication
      };
    };
  };
}
