{
  inputs,
  ...
}:
# Builds a NixOS system from a host record.
#
# `xlib` is the pure host value (lib/xlib.nix `mkXlib`) built in
# configurations/default.nix. It is handed to every module as the `xlib`
# argument, so modules read plain `xlib.*` data instead of `config.xlib.*`
# and the host record stays the single source of truth.
{
  xlib,
  modules ? [ ],
  system ? "x86_64-linux",
  ...
}:
let
  lib = inputs.nixpkgs.lib;
in
lib.nixosSystem {
  inherit
    system
    modules
    ;
  specialArgs = {
    inherit inputs;
    inherit xlib;
  };
}
