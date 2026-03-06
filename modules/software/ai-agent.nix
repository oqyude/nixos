{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  lol = import inputs.nixpkgs-beets {
    system = "x86_64-linux";
  };
in
{
  environment.systemPackages = [
    lol.open-interpreter
  ];
}
