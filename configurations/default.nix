{ inputs, ... }@flakeContext:
let
  lib = inputs.nixpkgs.lib;
  mkSystem = import ../lib/mkSystem.nix flakeContext;
  xlibLib = import ../lib/xlib.nix { inherit lib; };

  # One record per host. The attribute name IS the hostname, so it is written
  # exactly once; `hostname` is only needed where the attribute name is not
  # the real hostname (the `default` entry).
  #
  #   device   device type, must be a key of `devices` in lib/xlib.nix
  #   modules  module body for this host
  hosts = {
    default = {
      hostname = "nixos";
      device = "minimal";
      modules = [ ./any.nix ];
    };
    atoridu = {
      device = "primary";
      modules = [ ./mini-pc.nix ];
    };
    rydiwo = {
      device = "secondary";
      modules = [ ./mini-laptop.nix ];
    };
    otreca = {
      device = "vds";
      modules = [ ./vds.nix ];
    };
    sapphira = {
      device = "server";
      modules = [ ./server.nix ];
    };
    wsl = {
      device = "wsl";
      modules = [ ./wsl.nix ];
    };
  };

  mkHost =
    name:
    {
      device,
      modules,
      hostname ? name,
      ...
    }:
    let
      xlib = xlibLib.mkXlib {
        inherit hostname;
        type = device;
      };
    in
    {
      inherit xlib;
      system = mkSystem { inherit xlib modules; };
    };
in
{
  nixosConfigurations = lib.mapAttrs' (
    name: spec: lib.nameValuePair name (mkHost name spec).system
  ) hosts;

  # Per-host xlib values, for code that lives outside the module system
  # (deploy, overlays, pkgs).
  xlib = lib.mapAttrs' (name: spec: lib.nameValuePair name (mkHost name spec).xlib) hosts;

  nixOnDroidConfigurations = {
    epral = import ./mobile.nix flakeContext; # epral (Android device via nix-on-droid)
    # Alias so a plain `nix-on-droid switch` from a local clone
    # (~/.config/nix-on-droid) picks up the device config without `#epral`.
    default = import ./mobile.nix flakeContext;
  };
}
