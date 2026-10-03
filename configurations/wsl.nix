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

  # Enable SSH server on WSL NixOS so sapphira can drive it directly via a
  # ProxyCommand chain through the Windows OpenSSH layer. The shared
  # essentials/ssh.nix module wires host keys, sops-managed user keys, and
  # passwordless key auth — nothing to repeat here.
  host.ssh.enable = true;

  # Advertise this WSL instance as a remote Nix builder for sapphira (2
  # cores, the bottleneck host). All builder wiring — fixing the
  # `system-features` to drop the unsupported `kvm`, and adding the SSH
  # user `oqyude` to trusted-users — lives in modules/wsl/builder.nix.
  host.builder.enable = true;

  system.stateVersion = "24.11";
}
