{
  config,
  pkgs,
  ...
}:

let
  homeDir = "/home/yuyul";
  structureDir = "${homeDir}/Structure";
  sharedDir = "${structureDir}/Shared";
  storageDir = "${sharedDir}/Storage";
  programsDir = "${storageDir}/Programs";
  shared_settingsDir = "${storageDir}/Settings";
  settingsDir = "${shared_settingsDir}/YuYuL";
  #
  nixosDir = "${settingsDir}/NixOS";
in
{
  # NixOS
  fileSystems = {
    "${nixosDir}" = {
      device = "/etc/nixos";
      fsType = "none";
      options = [ "bind" ];
    };
  };
  #
  # Hyprland
  fileSystems = {
    "${homeDir}/.config/hypr" = {
      device = "${settingsDir}/hyprland";
      fsType = "none";
      options = [ "bind" ];
    };
  };

  # Nekoray
  fileSystems = {
    "${homeDir}/.config/nekoray" = {
      device = "${programsDir}/Nekoray/YuYuL";
      fsType = "none";
      options = [ "bind" ];
    };
  };
  # Syncthing
  fileSystems = {
    "${homeDir}/.config/syncthing" = {
      device = "${programsDir}/Syncthing/YuYuL";
      fsType = "none";
      options = [ "bind" ];
    };
  };
}
