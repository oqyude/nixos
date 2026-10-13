# Host: "rydiwo" (device: secondary)
#
# The host record lives in configurations/default.nix; this file is only the
# module body. `xlib` (identity, dirs, helpers) arrives as a module argument.
{
  lib,
  pkgs,
  xlib,
  inputs,
  ...
}:
{
  imports = with inputs; [
    nixos-hardware.nixosModules.chuwi-minibook-x
    ./hardware/mini-laptop.nix
    self.nixosModules.default
    ../modules/pxe-infra
  ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_stable;
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };

  fileSystems = xlib.helpers.mkNtfsMount {
    path = xlib.dirs.lamet-drive;
    uuid = "DC76BD3576BD116E";
    mask = "0000";
  };

  host.ssh.enable = true;
  hardware.intel-gpu-tools.enable = true;

  system.stateVersion = "26.05";

  # --------------------------------------------------------------------------
  # PXE infrastructure rig (L2 of docs/ARCHITECTURE.md).
  # The rig gives rydiwo an isolated Linux bridge
  # (`pxe-infra.bridge.name`, default `pxe0`) plus a MAC-filtered
  # dnsmasq DHCP server bound only to that bridge — the real LAN is
  # not touched. The QEMU guest (L4) is configured but NOT
  # autostarted: start it by hand with
  #   systemctl start pxe-infra-vm
  # when a test session needs it, and stop it the same way. Set
  # `vm.autostart = true` here to bring the VM up on every boot
  # (e.g. for a long unattended test run). See `modules/options.nix`
  # (options.pxe-infra.*) for the full option surface and
  # `modules/pxe-infra/` for the implementation.
  pxe-infra = {
    enable = true;
    bridge.address = "10.66.0.1";
    bridge.prefixLength = 24;
    vm = {
      enable = true;
      autostart = false;        # start manually when testing
    };
    dhcp.guests = [
      {
        mac      = "52:54:00:12:34:56";
        ip       = "10.66.0.10";
        hostname = "pxe-vm-01";      # optional
      }
    ];
  };
  # --------------------------------------------------------------------------
}
