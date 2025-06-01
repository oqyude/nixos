{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
 postgresql = {
      enable = false;
      #  ensureDatabases = [ "nextcloud" ];
      #  ensureUsers = [
      #    {
      #      name = "nextcloud"; # Здесь не хватает строчек\\
      #    }
      #  ];
    };
    immich = {
      enable = true;
      port = 2283;
      host = "0.0.0.0";
      openFirewall = true;
      accelerationDevices = null;
      machine-learning.enable = false;
     
    };
  };
  
  users.users.immich.extraGroups = [ "video" "render" ];
}
