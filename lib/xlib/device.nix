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
    }:
    let
      capabilities = devices.${type} or (throw "xlib: unknown device type '${type}', expected one of ${lib.concatStringsSep ", " (builtins.attrNames devices)}");
    in
    {
      inherit
        hostname
        type
        username
        ;
      isDesktop = capabilities.desktop;
      isHeadless = capabilities.headless;
    };
}