{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../pkgs/beets.nix
    ./containers
    ./nix-serve.nix
    ./builder.nix
    # ./tools
  ];
}
