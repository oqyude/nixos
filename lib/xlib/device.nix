{
  lib,
  ...
}:
# Supported device types and the identity record built from one.
#
# Single source of truth for host identity: hostname, type, username and the
# capability flags derived from the type. Replaces the old `lib.types.enum`
# in modules/options.nix and the hand-written type lists in modules/default.nix
# and home/home.nix.
let
  devices = {
    minimal = {
      desktop = false;
      headless = false;
    };
    primary = {
      desktop = true;
      headless = false;
    };
    secondary = {
      desktop = true;
      headless = false;
    };
    server = {
      desktop = false;
      headless = true;
    };
    vds = {
      desktop = false;
      headless = true;
    };
    wsl = {
      desktop = false;
      headless = true;
    };
    termux = {
      desktop = false;
      headless = true;
    };
  };
in
{
  inherit devices;

  # Unknown device type fails here, at flake level, with the valid list.
  mkDevice =
    {
      hostname,
      type,
      username ? "oqyude",
      # The primary user is pinned to 1000 rather than left to NixOS'
      # nextfree logic: the mount helpers below write uid=/gid= into
      # ntfs3/exfat options, and an NTFS/exFAT volume mounted with a
      # different id shows every file as owned by `nobody`.
      uid ? 1000,
      gid ? 1000,
    }:
    let
      capabilities = devices.${type} or (throw "xlib: unknown device type '${type}', expected one of ${lib.concatStringsSep ", " (builtins.attrNames devices)}");
    in
    {
      inherit
        hostname
        type
        username
        uid
        gid
        ;
      isDesktop = capabilities.desktop;
      isHeadless = capabilities.headless;
    };
}