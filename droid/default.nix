{ inputs, ... }@flakeContext:
{
  nixOnDroidConfigurations = {
    epral = import ./epral.nix flakeContext; # epral (Android via nix-on-droid)
  };
}
