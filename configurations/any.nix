# Host: "default" (device: minimal)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
#
# This is a TEMPLATE — never deployed. Real hosts use their own configurations
# (mini-pc.nix, server.nix, vds.nix, etc.) with their own disko + grub.
# The stubs below exist only so `nix flake check` and `nix build .#default`
# evaluate without assertion failures — they are never used to build a real
# system.
{
  inputs,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.default
  ];

  system.stateVersion = "26.05";

  # Stubs for `nix flake check`. Replace with real disko + hardware on
  # real hosts; never deploy this configuration.
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ];
  boot.loader.grub.configurationLimit = 50;
}
