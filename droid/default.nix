{ inputs, ... }@flakeContext:
{
  nixOnDroidConfigurations = {
    epral = import ./epral.nix flakeContext; # epral (Android via nix-on-droid)
    # Alias so a plain `nix-on-droid switch` from a local clone
    # (~/.config/nix-on-droid) picks up the device config without `#epral`.
    default = import ./epral.nix flakeContext;
  };
}
