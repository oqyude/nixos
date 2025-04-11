{
  description = "zeroq handmane";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #home-manager.url = "gitlab:rycee/home-manager/release-22.11";
  };
  outputs = { self, nixpkgs, home-manager }@inputs: {
    nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem {
      modules = [ ./configuration.nix ];
      specialArgs.inputs = inputs;
      system = "x86_64-linux";
    };
  };
}
