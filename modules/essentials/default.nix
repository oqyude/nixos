{
  config,
  ...
}:
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./settings.nix
    ./tty.nix
    ./users.nix
  ];

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
        ];
      };
    };
  };
}
