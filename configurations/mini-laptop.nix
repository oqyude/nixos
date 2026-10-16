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
    ../modules/server/engipy-backend.nix
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

  # engipy webapp backend на rydiwo: uvicorn + FastAPI + SBERT + torch.
  # Python-окружение через fetchPip — wheels с PyPI, без компиляции
  # (см. modules/server/engipy-backend.nix). Sapphira проксирует
  # engipy.zeroq.su/api/* на 192.168.1.102:8000 — это адрес rydiwo
  # в LAN.
  #
  # Сгенерировано в WSL nixos — см. requirements.nix + gen_reqs.py.
  host.engipy-backend = {
    enable = true;
    bindAddress = "0.0.0.0";
  };

  # Не засыпать при закрытии крышки: rydiwo используется как
  # headless-сервер для engipy (sapphira проксирует /api/* на него).
  # Если пользователь берёт ноутбук в руки — пусть остаётся правило
  # по умолчанию (suspend); но для unattended-режима нужно ignore.
  services.logind.lidSwitch = "ignore";
  services.logind.lidSwitchDocked = "ignore";

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
    bootloader.ipxeBinary = "snp.efi"; # SNP-only build, 310K, virtio-net-friendly
    vm = {
      enable = true;
      autostart = false; # start manually when testing
      memory = "4G"; # iPXE needs 2G+ heap to sanboot a 2G raw image
    };
    dhcp.guests = [
      {
        mac = "52:54:00:12:34:56";
        ip = "10.66.0.10";
        hostname = "pxe-vm-01"; # optional
      }
    ];
  };
  # --------------------------------------------------------------------------
}
