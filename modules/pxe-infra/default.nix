# pxe-infra — isolated private network for PXE VM guests (L2/L3 of
# docs/ARCHITECTURE.md). Provides a Linux bridge, a MAC-filtered
# DHCP server, a TFTP server (iPXE bootloader), and an HTTP server
# (kernel/initramfs/rootfs), so a fresh VM can netboot from this
# host without touching the real LAN.
#
# Master toggle: `pxe-infra.enable`. Submodules guard their own
# config with `lib.mkIf config.pxe-infra.enable`, so importing
# this umbrella alone has no effect on a host that opts out.
{
  config,
  lib,
  ...
}:
{
  imports = [
    ./bridge.nix
    ./dhcp.nix
    ./http.nix
    ./ipxe.nix
    ./report-sink.nix
    ./vm.nix
  ];

  # H_fix.2: chain-target option for autoexec.ipxe.
  #
  # Declared here (not in `modules/options.nix`) because this
  # task's scope is `modules/pxe-infra/` only — `modules/options.nix`
  # is outside that directory. NixOS modules merge option
  # declarations across files, so adding a new sub-attr
  # `bootloader.bypassFallback.enable` from this module is safe
  # alongside the `bootloader.enable` / `bootloader.ipxeBinary`
  # options already declared in `modules/options.nix`.
  #
  # H_fix.2-1+2: when `false` (default), autoexec.ipxe chains to
  # `boot.ipxe` (production sanboot). When `true`, autoexec.ipxe
  # chains to `boot-bypass.ipxe` (the H_fix.1b regression baseline:
  # kernel+initrd, no sanboot). Both scripts are always staged
  # (see ipxe.nix) — this option only flips the chain target.
  options.pxe-infra.bootloader.bypassFallback = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        When true, `autoexec.ipxe` chains to `boot-bypass.ipxe`
        (the H_fix.1b regression baseline — kernel+initrd, no
        sanboot) instead of `boot.ipxe` (the production sanboot
        path). Both scripts are always staged under
        `artifacts.root/http/`; this option only flips the
        chain target inside `autoexec.ipxe`. Set true to
        reproduce the H_fix.1b regression shape with a single
        config flip + rebuild, without touching `ipxe.nix`.
        Defaults to false: operators who don't set it see no
        behavior change beyond iPXE now running the sanboot
        chain (which is the production path the rig was
        designed for).
      '';
    };
  };

  config = lib.mkIf config.pxe-infra.enable {
    # Create the artifact directory tree at boot. TFTP and HTTP
    # both serve from here; the actual artifacts land in this tree
    # by whatever means (manual copy, deploy step, mkosi output
    # directory — see docs/OPEN-QUESTIONS.md B.9/B.10).
    #
    # The `L+` rules symlink the iPXE binary and boot.ipxe script
    # from /etc/static/pxe-infra/... (where the ipxe.nix module
    # drops them via environment.etc) into the served roots, so
    # `nixos-rebuild` upgrades of pkgs.ipxe are picked up at the
    # next boot without redeploying anything.
    systemd.tmpfiles.rules = [
      "d ${config.pxe-infra.artifacts.root} 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/http 0755 root root - -"
      "d ${config.pxe-infra.artifacts.root}/tftpboot 0755 root root - -"
      "L+ ${config.pxe-infra.artifacts.root}/tftpboot/${config.pxe-infra.bootloader.ipxeBinary} - - - - /etc/static/pxe-infra/tftpboot/${config.pxe-infra.bootloader.ipxeBinary}"
      "L+ ${config.pxe-infra.artifacts.root}/http/boot.ipxe - - - - /etc/static/pxe-infra/http/boot.ipxe"
      # H_fix.2-1+2: boot-bypass.ipxe — the H_fix.1b regression
      # baseline (kernel+initrd path). Mirrors the boot.ipxe rule
      # above. Both scripts are always staged so the chain target
      # can be flipped via `pxe-infra.bootloader.bypassFallback.enable`
      # without re-deploying artifacts. See ipxe.nix for the
      # writeText bodies and H_fix.2-9 for the regression scenario.
      "L+ ${config.pxe-infra.artifacts.root}/http/boot-bypass.ipxe - - - - /etc/static/pxe-infra/http/boot-bypass.ipxe"
      # autoexec.ipxe — chains to the HTTP-served chain target
      # (boot.ipxe by default, boot-bypass.ipxe when
      # `pxe-infra.bootloader.bypassFallback.enable = true`).
      # iPXE in UEFI mode looks for `autoexec.ipxe` on the same
      # TFTP server it was loaded from. The actual file is produced
      # by ipxe.nix via pkgs.writeText and dropped under
      # /etc/static/pxe-infra/tftpboot/; this rule symlinks it into
      # the served root. See ipxe.nix and
      # .agent/notes/T10-diagnostic-2026-10-14.md.
      "L+ ${config.pxe-infra.artifacts.root}/tftpboot/autoexec.ipxe - - - - /etc/static/pxe-infra/tftpboot/autoexec.ipxe"
    ];
  };
}
