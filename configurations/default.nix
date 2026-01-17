{ inputs, ... }@flakeContext:
{
  nixosConfigurations = {
    atoridu = import ./mini-pc.nix flakeContext; # atoridu
    rydiwo = import ./mini-laptop.nix flakeContext; # rydiwo
    otreca = import ./vds.nix flakeContext; # vds
    sapphira = import ./server.nix flakeContext; # sapphira
    wsl = import ./wsl.nix flakeContext; # wsl
  };
}
