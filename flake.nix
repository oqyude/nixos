{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/d19cf9dfc633816a437204555afeb9e722386b76";
    #"github:NixOS/nixpkgs/nixos-unstable";
    # "flake:nixpkgs/nixpkgs-unstable/4e1b0f54e477462aa0fda917e97f724e49460bb0";
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
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
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
        wsl = import ./hosts/wsl.nix flakeContext;
      };

    };
}
