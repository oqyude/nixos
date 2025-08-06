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
          "immich"
        ];
      };
    };
  };
}
