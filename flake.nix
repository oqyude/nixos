{
  description = "zeroq flake";

  inputs = {

    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    # last working commit - "github:NixOS/nixpkgs/f6db44a8daa59c40ae41ba6e5823ec77fe0d2124";
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
