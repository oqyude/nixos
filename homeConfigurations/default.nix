{ ... }@flakeContext:
{
  homeConfigurations = {
    default = import ./home.nix flakeContext;
  };
}
