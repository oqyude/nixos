{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../pkgs/beets.nix
    ./nix-serve.nix
    ./builder.nix
    # ./tools
    # ./containers removed 2026-10-10: contained only kokoro-tts.nix
    # which was archived to archive/containers/. The import resolved
    # to modules/wsl/containers/default.nix — now removed (dead).
  ];
}
