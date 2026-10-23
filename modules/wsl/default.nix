{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../pkgs/beets.nix
    # The WSL nix-serve module used to be a byte-identical copy of the server
    # one (md5 0aca1128...). Importing the server module directly keeps a
    # single source; its `sopsFile = ./secrets/nix-serve.yaml` then resolves
    # to modules/server/secrets/nix-serve.yaml, which is itself byte-identical
    # to the copy that used to live in modules/wsl/secrets/ (md5 af6e0441...),
    # so the evaluated configuration is unchanged.
    ../server/nix-serve.nix
    ./builder.nix
    # ./tools
    # ./containers removed 2026-10-10: contained only kokoro-tts.nix
    # which was archived to archive/containers/. The import resolved
    # to modules/wsl/containers/default.nix — now removed (dead).
  ];
}
