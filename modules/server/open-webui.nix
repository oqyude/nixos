{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  services = {
    open-webui = {
      enable = false;
      host = "0.0.0.0";
      port = 11112;
      openFirewall = true;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OPENAI_API_BASE_URL = "http://192.168.1.100:1234/v1";
        #OLLAMA_API_BASE_URL = "http://127.0.0.1:1234";
        WEBUI_AUTH = "True";
        ENABLE_SIGNUP = "False";
        ENABLE_SIGNUP_PASSWORD_CONFIRMATION = "True";
        ENABLE_VERSION_UPDATE_CHECK = "False";
      };
    };
  };
}
