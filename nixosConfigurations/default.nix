{ ... }@flakeContext:
{
  nixosConfigurations = {
    atoridu = import ./hosts/mini-pc.nix flakeContext; # atoridu
    lamet = import ./hosts/mini-laptop.nix flakeContext; # lamet
    otreca = import ./hosts/vds.nix flakeContext; # vds
    sapphira = import ./hosts/server.nix flakeContext; # sapphira
    wsl = import ./hosts/wsl.nix flakeContext; # wsl

    pub-vds = import ./hosts/pub-vds.nix flakeContext;
  };
}
