# Host: "default" (device: minimal)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  system.stateVersion = "26.05";
}
