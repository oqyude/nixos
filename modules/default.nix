{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./essentials
    #./services

    # Flake modules
    inputs.home-manager.nixosModules.home-manager # home-manager module
    inputs.nix-index-database.nixosModules.nix-index
  ];

  # defines global user
  users = {
    users = {
      "${inputs.zeroq.devices.admin}" = {
        isNormalUser = true;
        description = "Jor Oqyude";
        initialPassword = "1234";
        extraGroups = [
          "beets"
          "audio"
          "disk"
          "gamemode"
          "libvirtd"
          "networkmanager"
          "pipewire"
          "qemu-libvirtd"
          "wheel"
          "immich"
        ];
      };
    };
  };
}
