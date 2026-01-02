{
  config,
  pkgs,
  xlib,
  inputs,
  ...
}:
let
  v2raynPath = "${xlib.dirs.wsl-storage}/v2rayN";
in
{
  xdg = {
    dataFile = {
      "v2raynData" = {
        source = config.lib.file.mkOutOfStoreSymlink v2raynPath;
        target = "v2rayN";
      };
    };
  };
  home.packages = [
    pkgs.v2rayn
  ];
}
