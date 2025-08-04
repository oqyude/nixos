{ inputs, ... }@flakeContext:
{
  config,
  lib,
  ...
}:
{
  imports = with inputs; [
    ./essentials
    (import ./options.nix { inherit inputs; })

    # Flake modules
    home-manager.nixosModules.home-manager # home-manager module
    nix-index-database.nixosModules.nix-index
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

  # Options
  # options = {
  #   device = {
  #     type = lib.mkOption {
  #       type = lib.types.enum [
  #         "minimal"
  #         "primary"
  #         "server"
  #         "vds"
  #         "wsl"
  #       ];
  #       default = "minimal";
  #       description = "Type of device for this host.";
  #     };
  #     username = lib.mkOption {
  #       type = lib.types.str;
  #       default = "${inputs.zeroq.devices.admin}";
  #       description = "Username for host";
  #     };
  #   };
  # };
}
