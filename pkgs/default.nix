{ inputs, ... }@flakeContext:
let
  pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
in
{
  packages."x86_64-linux" = {
    immich = pkgs.callPackage ./immich/package.nix {};
  };
}
