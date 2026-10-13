# pxe-infra/ipxe — stage the iPXE EFI binary into the TFTP root
# and write a static boot.ipxe script into the HTTP root.
#
# Together with the `dhcp-boot` option configured in dhcp.nix,
# this completes the boot chain:
#   UEFI firmware
#     → TFTP:  artifacts.root/tftpboot/<ipxeBinary>
#     → runs iPXE
#     → HTTP:  http://<bridge.address>/boot.ipxe
#     → iPXE script sanboots the alpine-worker raw disk image
#
# The artifact itself is produced by build/mkosi/ in the
# pxe-infra-automation repo and rsynced into
# artifacts.root/http/<rev>/. A `latest/` symlink points at the
# newest <rev>, which the static boot.ipxe references.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.pxe-infra.enable && config.pxe-infra.bootloader.enable) {
    # iPXE binary from nixpkgs. We drop it under
    # /etc/static/pxe-infra/tftpboot/ via environment.etc; the
    # tmpfiles rule in default.nix symlinks from there into the
    # actual served TFTP root.
    environment.etc."pxe-infra/tftpboot/${config.pxe-infra.bootloader.ipxeBinary}".source =
      "${pkgs.ipxe}/${config.pxe-infra.bootloader.ipxeBinary}";

    # Static iPXE script, served by the L3 HTTP server. iPXE
    # fetches it via HTTP after the initial TFTP-boot of the
    # binary itself.
    #
    # `''${...}''` is Nix's escape for a literal `${...}` in a
    # multi-line string; iPXE uses `${boot-url}` as its own
    # variable substitution, which must survive into the output
    # verbatim.
    environment.etc."pxe-infra/http/boot.ipxe".source = pkgs.writeText "boot.ipxe" ''
      #!ipxe
      set boot-url http://${config.pxe-infra.bridge.address}/latest
      # sanboot (not imgfetch+boot) is the right primitive for
      # raw disk images: it presents the URL as a block device
      # to the firmware, and the firmware walks the partition
      # table to find a bootloader. `boot` tries to parse the
      # blob as a UEFI PE executable, which a 2 GB raw disk
      # is not.
      sanboot ''${boot-url}/alpine-worker.raw || goto retry
      :retry
      echo sanboot failed, retrying in 5s
      sleep 5
      sanboot ''${boot-url}/alpine-worker.raw
    '';
  };
}
