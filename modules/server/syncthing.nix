{
  config,
  xlib,
  inputs,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
  };
in
{
  services.syncthing = {
    enable = true;
    package = pkgs.syncthing;
    systemService = true;
    guiAddress = "0.0.0.0:8384";
    configDir = "${xlib.dirs.storage}/Syncthing/${xlib.device.hostname}";
    dataDir = "${xlib.dirs.server-home}";
    group = "users";
    user = "${xlib.device.username}";
  };
}
