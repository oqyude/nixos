# Host: "wsl" (device: wsl)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
{
  lib,
  modulesPath,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.self.nixosModules.default
  ];

  hardware = {
    graphics.enable = true;
  };

  networking = {
    firewall = {
      enable = false;
      allowPing = true;
    };
    enableIPv6 = true;
  };

  wsl = {
    enable = true;
    startMenuLaunchers = true;
    useWindowsDriver = true;
    defaultUser = xlib.device.username;
  };

  system.stateVersion = "24.11";
}
