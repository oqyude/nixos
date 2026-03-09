{ inputs, ... }@flakeContext:
{
  nixosOverlays = {
    default = import ./pkgs.nix flakeContext;
  };
}
