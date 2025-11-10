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
