{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  v2raynPath = "${xlib.dirs.wsl-storage}/v2rayN";
  # last-stable = import inputs.nixpkgs-last-unstable { system = "x86_64-linux"; };
in
{
  xdg = {
    dataFile = {
      "grampsData" = {
        source = config.lib.file.mkOutOfStoreSymlink v2raynPath;
        target = "gramps";
      };
    };
  };
  home.packages = [
    pkgs.v2rayn
  ];
}
