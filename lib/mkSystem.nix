{
  inputs,
  ...
}:
{
  deviceType,
  hostname ? null,
  modules ? [ ],
  system ? "x86_64-linux",
}:
let
  lib = inputs.nixpkgs.lib;
in
lib.nixosSystem {
  inherit system;
  modules = modules ++ [
    {
      xlib.device = {
        type = deviceType;
      }
      // lib.optionalAttrs (hostname != null) { inherit hostname; };
    }
  ];
  specialArgs = {
    inherit deviceType inputs;
  };
}
