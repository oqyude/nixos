{
  nixosConfigurations = {
    atoridu = import ./devices/mini-pc.nix flakeContext; # atoridu
    lamet = import ./devices/mini-laptop.nix flakeContext; # lamet
    otreca = import ./devices/vds.nix flakeContext; # vds
    sapphira = import ./devices/server.nix flakeContext; # sapphira
    wsl = import ./devices/wsl.nix flakeContext; # wsl
  };
}
