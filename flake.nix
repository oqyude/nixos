{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
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
      zeroq = import ./modules/vars.nix;
      flakeContext = { inherit inputs zeroq; };
    in

    {
      homeConfigurations = {
        "${zeroq.user-name}" = import ./home/${zeroq.user-name}.nix flakeContext;
        "${zeroq.server-name}" = import ./home/${zeroq.server-name}.nix flakeContext;
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
