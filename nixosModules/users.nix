{
  config,
  xlib,
  ...
}:
{
  xlib.device.username = "oqyude";

  users = {
    users = {
      "${xlib.device.username}" = {
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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKduJia+unaQQdN6X5syaHvnpIutO+yZwvfiCP4qKQ/P"
        ];
      };
    };
  };
}
