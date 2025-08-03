{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./essentials

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

  # Options
  options.device.type = lib.mkOption {
    type = lib.types.enum [
      "minimal"
      "primary"
      "server"
      "vds"
      "wsl"
    ];
    default = "minimal"; # Значение по умолчанию, если не указано
    description = "Type of device for this host.";
  };
}
