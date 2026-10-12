# pxe-infra — isolated private network for PXE VM guests (L2 of
# docs/ARCHITECTURE.md). Provides a Linux bridge plus a
# MAC-filtered DHCP server so a fresh VM can netboot from this
# host without touching the real LAN.
#
# Master toggle: `pxe-infra.enable`. Submodules guard their own
# config with `lib.mkIf config.pxe-infra.enable`, so importing
# this umbrella alone has no effect on a host that opts out.
{
  config,
  ...
}:
{
  imports = [
    ./bridge.nix
    ./dhcp.nix
  ];
}
