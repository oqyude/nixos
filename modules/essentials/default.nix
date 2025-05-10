{ inputs, ... }@flakeContext:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./extras/binary-cache.nix # list of caches
    ./extras/i18n.nix
    ./extras/nix-store.nix
    ./extras/packages.nix
    ./extras/system.nix
  ];

  users = {
    users = {
      "${inputs.zeroq.devices.admin}" = {
        isNormalUser = true;
        description = "Jor Oqyude";
        initialPassword = "1234";
        extraGroups = [
          "jackaudio"
          "audio"
          "disk"
          "gamemode"
          "libvirtd"
          "networkmanager"
          "pipewire"
          "qemu-libvirtd"
          "wheel"
        ];
      };
    };
  };

  programs = {
    git = {
      enable = true;
      config = {
        user = {
          name = "oqyude";
          email = "oqyude@gmail.com";
        };
      };
    };
    lazygit.enable = true;
    nh = {
      enable = true;
      flake = "${inputs.zeroq.nixos}";
      clean = {
        enable = true;
        extraArgs = "--keep 3 --keep-since 2d";
        dates = "daily";
      };
    };
  };
}
