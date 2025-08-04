{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    (import ./options.nix { inherit lib inputs; }) # Options

    # Flake modules
    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index # nix-index module
  ];

  # defines global user
  config.users = {
    users = {
      "${config.device.username}" = {
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
