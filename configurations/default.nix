{ ... }@flakeContext:
{
  nixosConfigurations = {
    atoridu = import ./mini-pc.nix flakeContext; # atoridu
    # lamet = import ./mini-laptop.nix flakeContext; # lamet
    otreca = import ./vds.nix flakeContext; # vds
    sapphira = import ./server.nix flakeContext; # sapphira
    wsl = import ./wsl.nix flakeContext; # wsl

    # pub-vds = import ./pub-vds.nix flakeContext;
  };
}
