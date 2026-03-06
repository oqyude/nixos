{
  config,
  inputs,
  lib,
  pkgs,
  xlib,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    system = "x86_64-linux";
  };
in
{
  environment.systemPackages = [
    master.open-interpreter
  ];
}
