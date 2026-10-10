{
  config,
  pkgs,
  xlib,
  ...
}:
{
  services.transmission = {
    enable = false;
    #credentialsFile = "${xlib.dirs.server-home}/server/transmission/settings.json";
    openRPCPort = true;
    package = pkgs.transmission_4;
    user = "${xlib.device.username}";
    group = "users";
    settings = {
      download-dir = "${xlib.dirs.server-home}/Downloads";
      incomplete-dir = "${xlib.dirs.server-home}/Downloads/Temp";
      incomplete-dir-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      umask = 0;
    };
  };
}
