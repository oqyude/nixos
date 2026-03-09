{
  config,
  xlib,
  pkgs,
  ...
}:
let
  user = "snity";
in
{
  users = {
    users = {
      "${user}" = {
        name = "${user}";
        isNormalUser = true;
        group = "users";
        description = "Snity";
        hashedPassword = "$y$j9T$851xwObfIp7SYzIyFtH.k1$mNofT2sxEAV50Kxgmwvqc6Kj/3B/fJoPP8qgn./siEB";
        homeMode = "700";
        home = "/home/${user}";
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
