{
  config,
  xlib,
  pkgs,
  ...
}:
{
  xlib.device.username = "snity";

  users = {
    users = {
      "${xlib.device.username}" = {
        name = "${xlib.device.username}";
        isNormalUser = true;
        group = "users";
        description = "Snity";
        hashedPasswordFile = "$y$j9T$851xwObfIp7SYzIyFtH.k1$mNofT2sxEAV50Kxgmwvqc6Kj/3B/fJoPP8qgn./siEB"; # hashed_password
        homeMode = "700";
        home = "/home/${xlib.device.username}";
        extraGroups = [
          "audio"
          "disk"
          "gamemode"
          "networkmanager"
          "pipewire"
          "wheel"
        ];
      };
    };
  };
}
