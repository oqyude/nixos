{ inputs, ... }@flakeContext:
let
  mkSystem = import ../lib/mkSystem.nix flakeContext;
in
{
  nixosConfigurations = {
    default = mkSystem (import ./any.nix); # default
    atoridu = mkSystem (import ./mini-pc.nix); # atoridu
    rydiwo = mkSystem (import ./mini-laptop.nix); # rydiwo
    otreca = mkSystem (import ./vds.nix); # vds
    sapphira = mkSystem (import ./server.nix); # sapphira
    wsl = mkSystem (import ./wsl.nix); # wsl
  };
  nixOnDroidConfigurations = {
    epral = import ./mobile.nix flakeContext; # epral (Android via nix-on-droid)
    # Alias so a plain `nix-on-droid switch` from a local clone
    # (~/.config/nix-on-droid) picks up the device config without `#epral`.
    default = import ./mobile.nix flakeContext;
  };
}
