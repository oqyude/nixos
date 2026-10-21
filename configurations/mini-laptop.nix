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

  # engipy webapp backend на rydiwo: uvicorn + FastAPI + ONNX-SBERT.
  # Python-окружение через pip-venv на rydiwo (см. modules/server/engipy-backend.nix).
  # Sapphira проксирует engipy.zeroq.su/api/* на 192.168.1.102:8000.
  #
  # model = путь к локальной ONNX-папке (экспорт `cointegrated/rubert-tiny2`
  # сделан в WSL nixos и разложен на rydiwo). HF Hub id
  # `cointegrated/rubert-tiny2` НЕ должен здесь стоять — это
  # триггерит optimum через from_pretrained() скачивать с HF и
  # конвертировать через torch, что падает в
  # `RuntimeError: could not create a primitive` в GELU activation.
  #
  # T-MULTI-MODEL-REGISTRY (commit cd64a8e, 2026-10-18): 3 модели
  # (rubert-tiny2 default + BAAI/bge-m3 + intfloat/multilingual-e5-large)
  # лежат на /mnt/lamet/engipy-models/. `model` указывает на default
  # (rubert-tiny2), `ENGIPY_MODELS_DIR` (`modelsDir`) — корень для всех
  # трёх (см. modules/server/engipy-backend.nix). Старая папка
  # /var/lib/engipy/model/cointegrated__rubert-tiny2/ больше не
  # используется и может быть удалена вручную после успешного deploy.
  host.engipy-backend = {
    enable = true;
    bindAddress = "0.0.0.0";
    # Default ONNX-чекпойнт rubert-tiny2 теперь лежит на /mnt/lamet/
    # (в ENGIPY_MODELS_DIR — см. engipy-backend.nix). Имя подпапки
    # фиксировано в `app/services/models.py:build_default_registry`.
    model = "/mnt/lamet/engipy-models/rubert-tiny2";
    # `modelsDir` остаётся дефолтным (/mnt/lamet/engipy-models).
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
    # ipxe.efi (universal, ~600K) instead of snp.efi (SNP-only, 310K).
    # snp.efi worked on linux-virt 6.18.56 but breaks on 6.18.57
    # (delivered via aports 2b1f5137, 2026-10-16, kernel commit
    # c967b365 — `PCI: Make pci_match_one_device() match on ID
    # instead of device`). The new drivers/pci/search.c
    # `match_pci_dev_by_id()` (uses pci_match_one_id()+pci_id_from_device())
    # fails to match the virtio-blk PCI device that snp.efi
    # presents through its SAN hook (the IDs reported by the SAN
    # path are not full device IDs). The kernel boots, but rootfs
    # fails to mount: `UUID=...: Can't lookup blockdev` →
    # `Mounting root: failed.` The universal `ipxe.efi` presents
    # the SAN device through a different code path that
    # successfully matches against the new pci_match machinery.
    # Verified end-to-end on rydiwo 2026-10-17 with explicit
    # `bootMode=pxe`: two independent verdict=PASS reports
    # (20261017T180654Z, 20261017T180730Z). See pxe-infra-automation
    # T14 in .agent/tasks/manifest.json for full RCA. The ~290K
    # extra TFTP volume vs snp.efi is negligible.
    bootloader.ipxeBinary = "ipxe.efi";
    vm = {
      enable = true;
      autostart = false; # start manually when testing
      memory = "4G"; # iPXE needs 2G+ heap to sanboot a 2G raw image
      # bootMode=pxe: the guest boots over the network (TFTP → iPXE →
      # HTTP → kernel+initrd) instead of from the attached raw image.
      # This is the production path for the READ-ONLY payload (T24):
      # the initramfs carries the squashfs rootfs inside itself, so
      # the guest needs no disk at all and the chain does not depend on
      # iPXE's SAN-boot extensions (T14/R1). `direct` remains the
      # legacy disk profile (the attached alpine-worker.raw).
      bootMode = "pxe";
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
