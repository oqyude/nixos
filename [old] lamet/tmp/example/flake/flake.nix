{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    #   home-manager = {
    #      url = "github:nix-community/home-manager";
    #      inputs.nixpkgs.follows = "nixpkgs";
    #    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        #      specialArgs = {inherit inputs;};
        modules = [
          ./configuration.nix
          #        #inputs.home-manager.nixosModules.default
        ];
      };
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.default;
    };
}
