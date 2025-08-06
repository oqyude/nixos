{ inputs, ...}@flakeContext:
let
  system = "x86_64-linux"; # Замени, если нужно
  pkgs = import inputs.nixpkgs { inherit system; };
  immich-s = import ./pkgs/immich/default.nix { inherit pkgs; };
in
{
      packages."x86_64-linux" = {
        immich = immich-s.package;
      };
}
