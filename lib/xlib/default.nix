# Pure host library: no module system involved.
#
# Aggregates the four concerns a host record is built from:
#   device.nix   identity + capability flags from the device type
#   dirs.nix     well-known paths, derived from username
#   helpers.nix  pure helper functions shared by modules
#
# `mkXlib` is called in flake-level code (configurations/default.nix) and
# handed to every module as the `xlib` argument via lib/mkSystem.nix, so
# modules read plain `xlib.*` values instead of `config.xlib.*` and nothing in
# xlib can be overridden per host — the host record is the only place to
# change it.
{
  lib,
  ...
}:
let
  inherit (import ./device.nix { inherit lib; })
    devices
    mkDevice
    ;

  # dirs.nix is itself a function of `username`, not an attrset.
  mkDirs = import ./dirs.nix;

  helpers = (import ./helpers.nix { inherit lib; });
in
{
  inherit
    devices
    helpers
    mkDevice
    mkDirs
    ;

  # Full host record: identity + capability flags + well-known paths +
  # shared helpers.
  mkXlib =
    {
      hostname,
      type,
      username ? "oqyude",
      uid ? 1000,
      gid ? 1000,
    }:
    let
      device = mkDevice {
        inherit
          hostname
          type
          username
          uid
          gid
          ;
      };
    in
    {
      device = {
        inherit
          hostname
          type
          username
          uid
          gid
          ;
      };
      isDesktop = device.isDesktop;
      isHeadless = device.isHeadless;
      dirs = mkDirs username;
      # Bind the host's ids into the mount helpers, so ntfs3/exfat options
      # carry the same uid/gid the primary user actually has.
      helpers = import ./helpers.nix {
        inherit lib;
        uid = device.uid;
        gid = device.gid;
      };
    };
}