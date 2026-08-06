{ inputs, ... }@flakeContext:
{
  nixosConfigurations = {
    default = import ./any.nix flakeContext; # default
    atoridu = import ./mini-pc.nix flakeContext; # atoridu
    rydiwo = import ./mini-laptop.nix flakeContext; # rydiwo
    otreca = import ./vds.nix flakeContext; # vds
    otreca-new = import ./vds-new.nix flakeContext; # vds-new
    sapphira = import ./server.nix flakeContext; # sapphira
    wsl = import ./wsl.nix flakeContext; # wsl
  };
  nixOnDroidConfigurations = {
    epral = import ./mobile.nix flakeContext; # epral (Android via nix-on-droid)
    # Alias so a plain `nix-on-droid switch` from a local clone
    # (~/.config/nix-on-droid) picks up the device config without `#epral`.
    default = import ./mobile.nix flakeContext;
  };
}
