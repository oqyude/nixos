{ ... }@flakeContext:
{
  nixosModules = {
    default = import ./base.nix flakeContext;
  };
}
