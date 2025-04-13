{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:

    let
      flakeContext = { inherit inputs; };
    in

    {

      homeConfigurations = {
        oqyude = import ./home/oqyude.nix flakeContext;
        extraSpecialArgs = {
          inherit (flakeContext) inputs;
        };
      };

      nixosConfigurations = {
        atoridu = import ./hosts/atoridu.nix flakeContext;
        sapphira = import ./hosts/sapphira.nix flakeContext;
        wsl = import ./hosts/sapphira.nix flakeContext;
      };

    };
}
